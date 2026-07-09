import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/cozy_theme.dart';
import '../canvas/canvas_bloc.dart';
import '../canvas/canvas_state.dart';

/// Cubit that derives the active [ThemeData] from the currently applied
/// oasis theme in [CanvasBloc].
class ThemeCubit extends Cubit<ThemeData> {
  final CanvasBloc canvasBloc;
  late final StreamSubscription _canvasSub;

  ThemeCubit({required this.canvasBloc})
      : super(CozyTheme.lightTheme) {
    // Derive theme whenever the canvas state changes.
    _canvasSub = canvasBloc.stream.listen(_onCanvasChanged);
    // Also derive immediately from the current state.
    _onCanvasChanged(canvasBloc.state);
  }

  void _onCanvasChanged(CanvasState canvasState) {
    if (canvasState is CanvasLoaded) {
      final activeItems = canvasState.items.where((i) => i.isPlaced).toList();
      if (activeItems.isNotEmpty) {
        final palette = ThemePalette.get(activeItems.first.name);
        emit(CozyTheme.buildTheme(palette));
        return;
      }
    }
    // Fallback: default theme.
    emit(CozyTheme.lightTheme);
  }

  @override
  Future<void> close() {
    _canvasSub.cancel();
    return super.close();
  }
}
