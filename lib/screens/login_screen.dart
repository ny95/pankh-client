import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../services/backend_api_service.dart';
import 'oauth_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isOauthLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().login(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } catch (_) {
      setState(() => _error = 'Login failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startGoogleOauth() async {
    setState(() {
      _error = null;
      _isOauthLoading = true;
    });
    try {
      final redirectUri =
          kIsWeb
              ? Uri.base.replace(path: '/', queryParameters: const {}, fragment: '').toString()
              : 'https://oauth.pankh.local/callback';
      final authUrl = await BackendApiService.fetchGoogleAuthUrl(
        redirectUri: redirectUri,
      );

      if (kIsWeb) {
        await launchUrl(
          Uri.parse(authUrl),
          webOnlyWindowName: '_self',
        );
        return;
      }

      if (!mounted) return;
      final callbackUri = await Navigator.of(context).push<Uri>(
        MaterialPageRoute(
          builder: (_) => OAuthLoginScreen(
            authUrl: authUrl,
            redirectUri: redirectUri,
            title: 'Continue with Google',
          ),
        ),
      );
      if (!mounted || callbackUri == null) return;
      final token = callbackUri.queryParameters['token'];
      final provider = callbackUri.queryParameters['provider'];
      final email = callbackUri.queryParameters['email'];
      if (token == null || provider == null || email == null) {
        throw Exception('OAuth callback did not include session details.');
      }
      await context.read<AuthProvider>().loginWithOAuth(
            email: email,
            provider: provider,
            sessionToken: token,
          );
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'OAuth login failed. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isOauthLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sign in to Pankh',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isOauthLoading ? null : _startGoogleOauth,
                      icon: _isOauthLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login_rounded),
                      label: const Text('Continue with Google'),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('or'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password / App Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Login with password'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
