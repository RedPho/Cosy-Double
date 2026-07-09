import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';


import '../../blocs/room/room_bloc.dart';
import '../../blocs/room/room_state.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) {
        final summary = state.sessionSummary;
        
        final durationMinutes = summary?['duration_minutes'] ?? 0;
        final tasksCompleted = summary?['tasks_completed'] ?? 0;
        final leavesEarned = summary?['leaves_earned'] ?? 0;
        final passiveLeaves = summary?['passive_leaves'] ?? 0;
        final activeLeaves = summary?['active_leaves'] ?? 0;
        final newBalance = summary?['new_balance'] ?? 0;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Confetti / Leaf Icon
                      const Text(
                        '🍃',
                        style: TextStyle(fontSize: 64),
                        textAlign: TextAlign.center,
                      ).animate()
                       .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2), duration: 600.ms, curve: Curves.bounceOut)
                       .shake(delay: 500.ms, hz: 6, duration: 400.ms),
                       
                      const SizedBox(height: 24),
                      
                      // Message
                      Text(
                        'Great job showing up today.',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0.0),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Every step counts. You stayed focused in silent company.',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                      
                      const SizedBox(height: 32),
                      
                      // Main Stat Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                          child: Column(
                            children: [
                              // Reward Count
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('+', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                                  Text(
                                    '$leavesEarned',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      letterSpacing: -1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Leaves 🍃', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
                                ],
                              ).animate()
                               .scale(delay: 400.ms, duration: 500.ms, curve: Curves.elasticOut)
                               .shake(delay: 900.ms, hz: 4, duration: 500.ms),
                               
                              const SizedBox(height: 12),
                              Text(
                                '(Passive Presence: $passiveLeaves 🍃 | Active Tasks: $activeLeaves 🍃)',
                                style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.45)),
                              ),
                              
                              const SizedBox(height: 24),
                              Divider(color: Theme.of(context).scaffoldBackgroundColor, height: 1),
                              const SizedBox(height: 24),
                              
                              // Stats grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricItem(
                                      context,
                                      '⏱️ Duration',
                                      '${durationMinutes}m',
                                    ),
                                  ),
                                  Container(width: 1.5, height: 40, color: Theme.of(context).scaffoldBackgroundColor),
                                  Expanded(
                                    child: _buildMetricItem(
                                      context,
                                      '✅ Tasks Done',
                                      '$tasksCompleted',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                      
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      FilledButton(
                        onPressed: () {
                          context.go('/lobby');
                        },
                        child: const Text('Return to Lobby'),
                      ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                      
                      const SizedBox(height: 12),
                      
                      OutlinedButton(
                        onPressed: () {
                          context.go('/oasis');
                        },
                        child: const Text('Go to My Oasis'),
                      ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(BuildContext context, String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 20),
        ),
      ],
    );
  }
}
