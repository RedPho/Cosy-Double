import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/cozy_theme.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/room.dart';
import '../../blocs/room/room_bloc.dart';
import '../../blocs/room/room_event.dart';
import '../../blocs/room/room_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';

class FocusScreen extends StatefulWidget {
  final int roomId;

  const FocusScreen({super.key, required this.roomId});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with TickerProviderStateMixin {
  final _taskController = TextEditingController();
  final List<int> _recentCompletedTasks = []; // To trigger "+2 🍃" popups

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<RoomBloc, RoomState>(
      listener: (context, state) {
        if (state.status == RoomStatus.sessionSummary) {
          // Re-fetch user details to update the global Leaf wallet balance
          context.read<AuthBloc>().add(AppStarted());
          context.go('/summary');
        }
      },
      builder: (context, state) {
        final currentRoom = state.rooms.cast<Room>().firstWhere(
          (r) => r.id == widget.roomId,
          orElse: () => state.activeSession != null
              ? state.rooms.cast<Room>().firstWhere(
                  (r) => r.id == state.activeSession!.roomId,
                  orElse: () => const Room(id: 0, name: 'Focus Room', category: 'Deep Work', isActive: true, activeUsers: []),
                )
              : const Room(id: 0, name: 'Focus Room', category: 'Deep Work', isActive: true, activeUsers: []),
        );
        final roomName = currentRoom.name;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 18),
                ),
                Text(
                  'Focusing in silence...',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.45), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              // Frictionless "Pack Up & Leave" Button
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                key: const ValueKey('pack_up_leave_btn'),
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<RoomBloc>().add(TerminateFocusSession());
                  },
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Pack Up & Leave'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: CozyTheme.radiusMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Silent Interaction Overlay/Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: CozyTheme.radiusMedium,
                  border: Border.all(color: cs.outline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Silent Support Zone 🤫',
                            style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
                          ),
                          Text(
                            'Send silent support to active focused members.',
                            style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.55)),
                          ),
                        ],
                      ),
                    ),
                    // Non-intrusive support buttons
                    Row(
                      children: ['👏', '☕', '🌟'].map((emoji) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: InkWell(
                            onTap: () {
                              context.read<RoomBloc>().add(SendSilentInteraction(emoji: emoji));
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              child: Text(emoji, style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              // Focus Room Avatars Canvas
              Expanded(
                child: _buildPresenceGrid(context, state),
              ),
              
              // Sticky Footer task manager
              _buildTinyStepsFooter(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresenceGrid(BuildContext context, RoomState state) {
    final cs = Theme.of(context).colorScheme;
    // If empty or loading, show current user
    final users = state.activePresenceUsers;
    
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAvatarCircle('You', const Text('Me', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), []),
            const SizedBox(height: 12),
            Text('Waiting for other focusers to join...', style: TextStyle(color: cs.onSurface.withOpacity(0.45))),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final email = user['email'] ?? 'User';
        final username = user['username']?.toString() ?? (email.isNotEmpty ? email.split('@')[0] : 'User');
        final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
        final userId = user['user_id'];
        
        // Find recent interactions for this user
        final userInteractions = state.activeInteractions.where((i) => i['user_id'] == userId).toList();
        
        final completedTasks = user['completed_tasks'] ?? 0;
        final totalTasks = user['total_tasks'] ?? 0;
        final currentTask = user['current_task']?.toString() ?? '';
        final hasTasks = totalTasks > 0;
        final progress = hasTasks ? (completedTasks / totalTasks).toDouble() : null;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAvatarCircle(
              email, 
              Text(
                initial,
                style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              userInteractions,
              progress: progress,
            ),
            const SizedBox(height: 8),
            Text(
              username, // Short name
              style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
            if (hasTasks) ...[
              const SizedBox(height: 4),
              Text(
                '$completedTasks/$totalTasks Done',
                style: TextStyle(fontSize: 12, color: cs.secondary, fontWeight: FontWeight.w600),
              ),
            ],
            if (currentTask.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                currentTask,
                style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.6), fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (user['joined_at'] != null && user['joined_at'].toString().isNotEmpty) ...[
              const SizedBox(height: 2),
              _DurationTimer(joinedAtString: user['joined_at'].toString()),
            ]
          ],
        );
      },
    );
  }

  Widget _buildAvatarCircle(String key, Widget child, List<dynamic> interactions, {double? progress}) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Presence Ring: Animated pulse border
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cs.secondary.withOpacity(0.5), width: 3),
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.12, 1.12), duration: 2.seconds, curve: Curves.easeInOut),
        
        // Inner Ring / Progress
        SizedBox(
          width: 80,
          height: 80,
          child: progress != null
              ? TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 4,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: cs.secondary,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 2),
                  ),
                ),
        ),
        
        // Main Avatar Circle
        CircleAvatar(
          radius: 36,
          backgroundColor: cs.secondary,
          child: child,
        ),
        
        // Floating Silent Interaction Zone (Emoji overlays)
        if (interactions.isNotEmpty)
          Positioned(
            top: -24,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: interactions.map((inter) {
                final emoji = inter['emoji'];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ).animate()
                 .scale(duration: 300.ms, curve: Curves.bounceOut)
                 .slideY(begin: 0.2, end: -0.2, duration: 600.ms)
                 .fadeOut(delay: 2.seconds, duration: 800.ms);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTinyStepsFooter(BuildContext context, RoomState state) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 24.0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tiny Steps 🍃',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 12),
            
            // Task List
            if (state.activeTasks.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.activeTasks.length,
                  itemBuilder: (context, index) {
                    final task = state.activeTasks[index];
                    final isCompleted = task.isCompleted;
                    
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: task.isActive && !isCompleted ? cs.primaryContainer.withOpacity(0.3) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: isCompleted ? null : () {
                              context.read<RoomBloc>().add(SetTaskActive(taskId: task.id));
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isCompleted,
                                    activeColor: cs.secondary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: isCompleted
                                        ? null // Already checked, cannot uncheck for economy logic integrity
                                        : (val) {
                                            if (val == true) {
                                              setState(() {
                                                _recentCompletedTasks.add(task.id);
                                              });
                                              context.read<RoomBloc>().add(CompleteSessionTask(taskId: task.id));
                                              
                                              // Remove pop-up after 1.5 seconds
                                              Timer(const Duration(milliseconds: 1500), () {
                                                setState(() {
                                                  _recentCompletedTasks.remove(task.id);
                                                });
                                              });
                                            }
                                          },
                                  ),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                        color: isCompleted ? Colors.grey : (task.isActive ? cs.primary : cs.onSurface),
                                        fontWeight: task.isActive && !isCompleted ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (!isCompleted)
                                    IconButton(
                                      icon: Icon(
                                        task.isActive ? Icons.star : Icons.star_border,
                                        color: task.isActive ? cs.primary : Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        context.read<RoomBloc>().add(SetTaskActive(taskId: task.id));
                                      },
                                      tooltip: 'Set as active task',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Floating "+2 🍃" reward animation
                        if (_recentCompletedTasks.contains(task.id))
                          Positioned(
                            left: 12,
                            top: 4,
                            child: const Text(
                              '+2 🍃',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ).animate()
                             .scale(duration: 300.ms, curve: Curves.bounceOut)
                             .slideY(begin: 0.0, end: -1.5, duration: 1.seconds)
                             .fadeOut(delay: 500.ms, duration: 500.ms),
                          ),
                      ],
                    );
                  },
                ),
              ),
              
            const SizedBox(height: 8),
            
            // Add Task input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      hintText: 'What is your next tiny step?',
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: CozyTheme.radiusMedium,
                        borderSide: BorderSide(color: cs.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: CozyTheme.radiusMedium,
                        borderSide: BorderSide(color: cs.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: CozyTheme.radiusMedium,
                        borderSide: BorderSide(color: cs.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onSubmitted: (val) {
                      _submitTask(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _submitTask(context),
                  icon: Icon(Icons.add, color: cs.onPrimary),
                  style: IconButton.styleFrom(
                    backgroundColor: cs.secondary,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(borderRadius: CozyTheme.radiusMedium),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitTask(BuildContext context) {
    if (_taskController.text.trim().isNotEmpty) {
      context.read<RoomBloc>().add(AddSessionTask(title: _taskController.text.trim()));
      _taskController.clear();
    }
  }
}

class _DurationTimer extends StatefulWidget {
  final String joinedAtString;

  const _DurationTimer({required this.joinedAtString});

  @override
  State<_DurationTimer> createState() => _DurationTimerState();
}

class _DurationTimerState extends State<_DurationTimer> {
  Timer? _timer;
  String _durationText = '';

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateDuration());
  }

  @override
  void didUpdateWidget(covariant _DurationTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.joinedAtString != widget.joinedAtString) {
      _updateDuration();
    }
  }

  void _updateDuration() {
    try {
      final joinedAt = DateTime.parse(widget.joinedAtString).toLocal();
      final diff = DateTime.now().difference(joinedAt);
      final minutes = diff.inMinutes;
      setState(() {
        if (minutes < 1) {
          _durationText = 'Just joined';
        } else if (minutes < 60) {
          _durationText = 'Here for ${minutes}m';
        } else {
          final hours = diff.inHours;
          final remainingMinutes = minutes % 60;
          _durationText = 'Here for ${hours}h ${remainingMinutes}m';
        }
      });
    } catch (e) {
      setState(() {
        _durationText = '';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_durationText.isEmpty) return const SizedBox.shrink();
    return Text(
      _durationText,
      style: TextStyle(
        fontSize: 10,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}
