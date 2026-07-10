import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/cozy_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo / Title Icon
                      Icon(
                        Icons.spa,
                        size: 64,
                        color: cs.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cozy Double',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shame-free body doubling for focus & flow.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Nickname field
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Choose a Nickname (optional)',
                          hintText: 'e.g. Cozy Panda',
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
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Error State
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthError) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                state.message,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      
                      // Buttons
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthLoading) {
                            return Center(
                              child: CircularProgressIndicator(color: cs.primary),
                            );
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final nickname = _usernameController.text.trim();
                                    context.read<AuthBloc>().add(
                                          LoginAsGuestRequested(
                                            username: nickname.isNotEmpty ? nickname : null,
                                          ),
                                        );
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: CozyTheme.radiusMedium),
                                ),
                                child: const Text('Enter Oasis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => _showPrivacyPolicyDialog(context),
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.55)),
                            ),
                          ),
                          Text(
                            '•',
                            style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.3)),
                          ),
                          TextButton(
                            onPressed: () => _showTermsDialog(context),
                            child: Text(
                              'Terms of Service',
                              style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.55)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
              '3. Third-party services:\n'
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
}
