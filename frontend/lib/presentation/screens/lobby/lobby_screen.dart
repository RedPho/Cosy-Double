import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/cozy_theme.dart';
import '../../../domain/entities/room.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/room/room_bloc.dart';
import '../../blocs/room/room_event.dart';
import '../../blocs/room/room_state.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RoomBloc>().add(FetchRooms());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<RoomBloc, RoomState>(
      listener: (context, state) {
        if (state.status == RoomStatus.inSession && state.activeSession != null) {
          context.go('/focus/${state.activeSession!.roomId}');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.spa, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Cozy Double',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 22),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.coffee, color: Colors.brown),
              tooltip: 'Buy me a coffee',
              onPressed: () => _showSupportDialog(context),
            ),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                int leaves = 0;
                if (authState is Authenticated) {
                  leaves = authState.user.leavesBalance;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    avatar: const Text('🍃', style: TextStyle(fontSize: 16)),
                    label: Text('$leaves', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
                    backgroundColor: cs.surface,
                    side: BorderSide(color: cs.outline),
                    shape: RoundedRectangleBorder(borderRadius: CozyTheme.radiusMedium),
                    onPressed: () => context.push('/oasis'),
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: cs.onSurface),
              onSelected: (value) {
                if (value == 'logout') {
                  context.read<AuthBloc>().add(LoggedOut());
                } else if (value == 'change_nickname') {
                  _showChangeNicknameDialog(context);
                } else if (value == 'privacy') {
                  _showPrivacyPolicyDialog(context);
                } else if (value == 'terms') {
                  _showTermsDialog(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'privacy',
                  child: Row(children: [Icon(Icons.privacy_tip_outlined, size: 20), SizedBox(width: 8), Text('Privacy Policy')]),
                ),
                const PopupMenuItem(
                  value: 'terms',
                  child: Row(children: [Icon(Icons.description_outlined, size: 20), SizedBox(width: 8), Text('Terms of Service')]),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'change_nickname',
                  child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Change Nickname')]),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(children: [Icon(Icons.exit_to_app, size: 20), SizedBox(width: 8), Text('Log Out')]),
                ),
              ],
            ),
          ],
        ),
        body: BlocBuilder<RoomBloc, RoomState>(
          builder: (context, state) {
            // Loading state
            if (state.status == RoomStatus.loading && state.rooms.isEmpty) {
              return Center(child: CircularProgressIndicator(color: cs.primary));
            }

            // Error state
            if (state.status == RoomStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 48, color: cs.outline),
                    const SizedBox(height: 16),
                    Text('Could not connect', style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.read<RoomBloc>().add(FetchRooms()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // No rooms seeded yet (shouldn't normally happen)
            if (state.rooms.isEmpty) {
              return Center(child: Text('No focus room found.', style: TextStyle(color: cs.onSurface.withOpacity(0.5))));
            }

            // ── Single Focus Room ───────────────────────────────────────────
            final room = state.rooms.first;
            final activeCount = room.activeUsers.length;

            return RefreshIndicator(
              onRefresh: () async => context.read<RoomBloc>().add(FetchRooms()),
              color: cs.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Greeting
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        String greeting = 'Ready to focus?';
                        if (authState is Authenticated) {
                          final email = authState.user.email;
                          final name = email.split('@').first;
                          greeting = 'Welcome back, $name.';
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(greeting, style: Theme.of(context).textTheme.headlineLarge),
                            const SizedBox(height: 6),
                            Text(
                              'A shared space to do the work that matters.',
                              style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.55)),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // ── Hero Room Card ──────────────────────────────────────
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: CozyTheme.radiusLarge,
                        side: BorderSide(color: cs.outline.withOpacity(0.4), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Room header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withOpacity(0.12),
                                    borderRadius: CozyTheme.radiusMedium,
                                  ),
                                  child: Icon(Icons.self_improvement_rounded, color: cs.primary, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(room.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        activeCount == 0
                                            ? 'Be the first to arrive 🌱'
                                            : '$activeCount ${activeCount == 1 ? 'person' : 'people'} focusing now',
                                        style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.55)),
                                      ),
                                    ],
                                  ),
                                ),
                                // Live indicator dot
                                if (activeCount > 0)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.shade400,
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.greenAccent.shade400.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)],
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Avatar row
                            if (activeCount > 0) ...[
                              SizedBox(
                                height: 36,
                                child: Stack(
                                  children: List.generate(
                                    activeCount > 7 ? 7 : activeCount,
                                    (index) {
                                      final email = room.activeUsers[index];
                                      final letter = email.isNotEmpty ? email[0].toUpperCase() : '?';
                                      return Container(
                                        margin: EdgeInsets.only(left: index * 22.0),
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: index % 2 == 0 ? cs.secondary : cs.primary.withOpacity(0.7),
                                          child: Text(letter, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              if (activeCount > 7)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('+${activeCount - 7} more', style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
                                ),
                              const SizedBox(height: 24),
                            ],

                            // Enter button
                            BlocBuilder<RoomBloc, RoomState>(
                              builder: (context, state) {
                                final isLoading = state.status == RoomStatus.loading;
                                return SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: FilledButton.icon(
                                    onPressed: isLoading ? null : () => context.read<RoomBloc>().add(StartFocusSession(roomId: room.id)),
                                    icon: isLoading
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.play_arrow_rounded),
                                    label: Text(isLoading ? 'Joining…' : 'Start Focusing', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: CozyTheme.radiusMedium)),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // How it works hint
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.5),
                        borderRadius: CozyTheme.radiusMedium,
                        border: Border.all(color: cs.outline.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('How it works', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface.withOpacity(0.7))),
                          const SizedBox(height: 10),
                          _hintRow(cs, '🍃', 'Earn leaves for every minute of focus'),
                          _hintRow(cs, '✅', 'Complete tasks to earn bonus leaves'),
                          _hintRow(cs, '🎨', 'Spend leaves on themes in the Oasis'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _hintRow(ColorScheme cs, String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }

  void _showChangeNicknameDialog(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    String currentName = '';
    if (state is Authenticated) {
      currentName = state.user.username;
    }
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Change Nickname'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Nickname',
              border: OutlineInputBorder(borderRadius: CozyTheme.radiusMedium),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  context.read<AuthBloc>().add(UpdateNicknameRequested(username: newName));
                  Navigator.of(ctx).pop();
                }
              },
              child: Text('Save', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: const SingleChildScrollView(
            child: Text(
              'Cozy Double Privacy Policy\n\n'
              'Last Updated: July 2026\n\n'
              '1. Information We Collect:\n'
              'We only collect your email address for account authentication. No third-party profiling is performed.\n\n'
              '2. Data Security:\n'
              'Your focus history, earned leaves, and unlocked items are stored securely on our central database. Passwords are fully hashed.\n\n'
              '4. Monetization & Purchases\n'
              'Currently, you can purchase all themes using focus leaves. In the future, we may introduce premium cosmetics.\n\n'
              'For full guidelines or queries, reach support at privacy@cozydouble.com.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Terms of Service'),
          content: const SingleChildScrollView(
            child: Text(
              'Cozy Double Terms of Service\n\n'
              'Last Updated: July 2026\n\n'
              '1. Terms Acceptance:\n'
              'By signing up for Cozy Double, you agree to our fair focus policy. Automated scripts/bots simulating focus sessions to farm leaves are prohibited.\n\n'
              '2. Microtransactions & Economy:\n'
              'Themes purchased with leaves or USD are tied to your user account and cannot be exchanged for physical currency.\n\n'
              '3. Disclaimer:\n'
              'Cozy Double is provided "as is". We are not responsible for accidental data loss or server downtime.\n\n'
              'Enjoy focusing!',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Support Cozy Double ☕'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cozy Double is run entirely on voluntary donations to cover server hosting costs.\n\n'
                'If you enjoy using the app to focus, please consider buying us a coffee!',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.coffee),
              label: const Text('Buy me a coffee'),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you so much for your support! ☕ (Simulation)')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
