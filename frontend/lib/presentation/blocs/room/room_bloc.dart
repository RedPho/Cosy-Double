import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/network/api_client.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/repositories/room_repository.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final RoomRepository roomRepository;
  final ApiClient apiClient;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool _isDisconnectingIntentionally = false;

  RoomBloc({required this.roomRepository, required this.apiClient}) : super(const RoomState()) {
    on<FetchRooms>(_onFetchRooms);
    on<StartFocusSession>(_onStartFocusSession);
    on<AddSessionTask>(_onAddSessionTask);
    on<CompleteSessionTask>(_onCompleteSessionTask);
    on<SetTaskActive>(_onSetTaskActive);
    on<TerminateFocusSession>(_onTerminateFocusSession);
    
    // WS Handlers
    on<ConnectWebSocket>(_onConnectWebSocket);
    on<WebSocketReceived>(_onWebSocketReceived);
    on<SendSilentInteraction>(_onSendSilentInteraction);
    on<RemoveInteraction>(_onRemoveInteraction);
    on<DisconnectWebSocket>(_onDisconnectWebSocket);
  }

  Future<void> _onFetchRooms(FetchRooms event, Emitter<RoomState> emit) async {
    emit(state.copyWith(status: RoomStatus.loading));
    try {
      final rooms = await roomRepository.getRooms();
      emit(state.copyWith(status: RoomStatus.loaded, rooms: rooms));
    } catch (e) {
      emit(state.copyWith(status: RoomStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onStartFocusSession(StartFocusSession event, Emitter<RoomState> emit) async {
    emit(state.copyWith(status: RoomStatus.loading));
    try {
      _isDisconnectingIntentionally = false;
      _reconnectTimer?.cancel();
      final session = await roomRepository.startSession(event.roomId);
      emit(state.copyWith(
        status: RoomStatus.inSession,
        activeSession: session,
        activeTasks: [],
        activePresenceUsers: [],
        activeInteractions: [],
      ));
      
      // Connect WebSocket automatically on session start
      add(ConnectWebSocket(roomId: event.roomId));
    } catch (e) {
      emit(state.copyWith(status: RoomStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddSessionTask(AddSessionTask event, Emitter<RoomState> emit) async {
    if (state.activeSession == null) return;
    try {
      final task = await roomRepository.addTask(state.activeSession!.id, event.title);
      final updatedTasks = List<Task>.from(state.activeTasks)..add(task);
      emit(state.copyWith(activeTasks: updatedTasks));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onCompleteSessionTask(CompleteSessionTask event, Emitter<RoomState> emit) async {
    try {
      final updatedTask = await roomRepository.completeTask(event.taskId);
      final updatedTasks = state.activeTasks.map((t) {
        return t.id == event.taskId ? updatedTask : t;
      }).toList();
      emit(state.copyWith(activeTasks: updatedTasks));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onSetTaskActive(SetTaskActive event, Emitter<RoomState> emit) async {
    try {
      final updatedTask = await roomRepository.activateTask(event.taskId);
      final updatedTasks = state.activeTasks.map((t) {
        if (t.id == event.taskId) {
          return updatedTask;
        } else {
          // Local optimistic update for other tasks
          return Task(
            id: t.id,
            sessionId: t.sessionId,
            userId: t.userId,
            title: t.title,
            isCompleted: t.isCompleted,
            isActive: false,
          );
        }
      }).toList();
      emit(state.copyWith(activeTasks: updatedTasks));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onTerminateFocusSession(TerminateFocusSession event, Emitter<RoomState> emit) async {
    if (state.activeSession == null) return;
    final sessionId = state.activeSession!.id;
    
    _isDisconnectingIntentionally = true;
    _reconnectTimer?.cancel();
    
    // Disconnect WebSocket first (Immediate termination)
    add(DisconnectWebSocket());
    
    emit(state.copyWith(status: RoomStatus.loading));
    try {
      final summary = await roomRepository.terminateSession(sessionId);
      emit(state.copyWith(
        status: RoomStatus.sessionSummary,
        sessionSummary: summary,
        activeSession: null,
        activeTasks: [],
      ));
    } catch (e) {
      emit(state.copyWith(status: RoomStatus.error, errorMessage: e.toString()));
    }
  }

  // WebSocket Methods
  Future<void> _onConnectWebSocket(ConnectWebSocket event, Emitter<RoomState> emit) async {
    await _closeWebSocket();
    try {
      final url = await apiClient.getWebSocketUrl(event.roomId);
      print("🔌 RoomBloc: Connecting to WebSocket: $url");
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _subscription = _channel!.stream.listen(
        (message) {
          print("📥 RoomBloc: Received WS Message: $message");
          add(WebSocketReceived(data: message));
        },
        onError: (err) {
          print("❌ RoomBloc: WS Stream Error: $err");
          add(DisconnectWebSocket());
          _scheduleReconnection(event.roomId);
        },
        onDone: () {
          print("ℹ️ RoomBloc: WS Stream Closed (Done)");
          add(DisconnectWebSocket());
          _scheduleReconnection(event.roomId);
        },
      );
    } catch (e) {
      print("❌ RoomBloc: Failed to establish WS connection: $e");
      add(DisconnectWebSocket());
      _scheduleReconnection(event.roomId);
    }
  }

  void _scheduleReconnection(int roomId) {
    if (_isDisconnectingIntentionally || state.activeSession == null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isDisconnectingIntentionally && state.activeSession != null) {
        print("🔄 RoomBloc: Attempting to reconnect to WebSocket room $roomId...");
        add(ConnectWebSocket(roomId: roomId));
      }
    });
  }

  void _onWebSocketReceived(WebSocketReceived event, Emitter<RoomState> emit) {
    try {
      final payload = jsonDecode(event.data);
      final type = payload['type'];
      
      if (type == 'presence') {
        final users = payload['users'] as List;
        emit(state.copyWith(activePresenceUsers: users));
      } else if (type == 'interaction') {
        final interaction = {
          'user_id': payload['user_id'],
          'email': payload['email'],
          'emoji': payload['interaction'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        // Add interaction to state list
        final updatedInteractions = List.from(state.activeInteractions)..add(interaction);
        emit(state.copyWith(activeInteractions: updatedInteractions));
        
        // Remove after 3 seconds to clear screen space safely via BLoC queue
        Timer(const Duration(seconds: 3), () {
          if (!isClosed) {
            add(RemoveInteraction(interaction: interaction));
          }
        });
      }
    } catch (_) {}
  }

  void _onSendSilentInteraction(SendSilentInteraction event, Emitter<RoomState> emit) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'interaction',
        'interaction': event.emoji,
      }));
    }
  }

  void _onDisconnectWebSocket(DisconnectWebSocket event, Emitter<RoomState> emit) {
    _closeWebSocket();
    emit(state.copyWith(activePresenceUsers: [], activeInteractions: []));
  }

  void _onRemoveInteraction(RemoveInteraction event, Emitter<RoomState> emit) {
    final currentList = List.from(state.activeInteractions);
    currentList.remove(event.interaction);
    emit(state.copyWith(activeInteractions: currentList));
  }

  Future<void> _closeWebSocket() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  @override
  Future<void> close() {
    _reconnectTimer?.cancel();
    _closeWebSocket();
    return super.close();
  }
}
