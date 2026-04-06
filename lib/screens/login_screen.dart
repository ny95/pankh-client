import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../services/backend_api_service.dart';
import 'oauth_login_screen.dart';

enum _LoginStep { identity, lookup, found, manual, failed }
enum _ManualConfigStep { imap, smtp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  static const List<String> _backgroundImages = [
    'assets/images/theme-mccutcheon 2.jpg',
    'assets/images/theme-mccutcheon.jpg',
    'assets/images/theme-mirrographer.jpg',
    'assets/images/theme-nicolas-poupart.jpg',
    'assets/images/theme-padrinan.jpg',
    'assets/images/theme-pixabay 2.jpg',
    'assets/images/theme-pixabay.jpg',
    'assets/images/theme-quangnguyenvinh.jpg',
    'assets/images/theme-therato.jpg',
  ];
  static const List<String> _webBackgroundImages = [
    'assets/images/thumbnail-theme-mccutcheon 2.jpg',
    'assets/images/thumbnail-theme-mccutcheon.jpg',
    'assets/images/thumbnail-theme-mirrographer.jpg',
    'assets/images/thumbnail-theme-nicolas-poupart.jpg',
    'assets/images/thumbnail-theme-padrinan.jpg',
    'assets/images/thumbnail-theme-pixabay 2.jpg',
    'assets/images/thumbnail-theme-pixabay.jpg',
    'assets/images/thumbnail-theme-quangnguyenvinh.jpg',
    'assets/images/thumbnail-theme-therato.jpg',
  ];
  static const List<String> _setupAuthMethodOptions = [
    'Autodetect',
    'No Authentication',
    'Normal password',
    'Encrypted password',
    'Kerberos / GSSAPI',
    'NTLM',
    'TLS Certificate',
  ];

  final _identityFormKey = GlobalKey<FormState>();
  final _manualFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _imapHostController = TextEditingController();
  final _imapPortController = TextEditingController(text: '993');
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController(text: '587');

  _LoginStep _step = _LoginStep.identity;
  bool _isOauthLoading = false;
  bool _isSubmitting = false;
  String? _error;
  EmailServerLookupResult? _lookupResult;
  bool _imapSecure = true;
  bool _smtpSecure = true;
  int _lookupRequestId = 0;
  String _selectedAuthMethod = 'Autodetect';
  _ManualConfigStep _manualConfigStep = _ManualConfigStep.imap;
  late final String _backgroundImage;

  @override
  void initState() {
    super.initState();
    final images = kIsWeb ? _webBackgroundImages : _backgroundImages;
    _backgroundImage = images[Random().nextInt(images.length)];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _imapHostController.dispose();
    _imapPortController.dispose();
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    super.dispose();
  }

  Future<void> _startLookup() async {
    final form = _identityFormKey.currentState;
    if (form == null || !form.validate()) return;

    final requestId = ++_lookupRequestId;
    setState(() {
      _error = null;
      _lookupResult = null;
      _step = _LoginStep.lookup;
    });

    try {
      final result = await BackendApiService.lookupEmailConfig(
        email: _emailController.text.trim(),
      );
      if (!mounted || requestId != _lookupRequestId) return;

      _lookupResult = result;
      _applyLookupDefaults(result);
      setState(() {
        _step = result.found ? _LoginStep.found : _LoginStep.failed;
      });
    } catch (_) {
      if (!mounted || requestId != _lookupRequestId) return;
      _applyFallbackDefaults();
      setState(() {
        _error = 'Unable to look up server settings right now.';
        _step = _LoginStep.failed;
      });
    }
  }

  void _applyLookupDefaults(EmailServerLookupResult result) {
    final domain = result.domain.isNotEmpty ? result.domain : _emailDomain;
    _imapHostController.text = result.imap?.host ?? 'imap.$domain';
    _imapPortController.text = '${result.imap?.port ?? 993}';
    _imapSecure = result.imap?.secure ?? true;
    _smtpHostController.text = result.smtp?.host ?? 'smtp.$domain';
    _smtpPortController.text = '${result.smtp?.port ?? 587}';
    _smtpSecure = result.smtp?.secure ?? true;
  }

  void _applyFallbackDefaults() {
    final domain = _emailDomain;
    _imapHostController.text = domain.isEmpty ? '' : 'imap.$domain';
    _imapPortController.text = '993';
    _imapSecure = true;
    _smtpHostController.text = domain.isEmpty ? '' : 'smtp.$domain';
    _smtpPortController.text = '587';
    _smtpSecure = true;
  }

  Future<void> _completeLogin({required bool cacheConfig}) async {
    final form = _manualFormKey.currentState;
    if (form == null || !form.validate()) return;

    final imapPort = int.tryParse(_imapPortController.text.trim());
    final smtpPort = int.tryParse(_smtpPortController.text.trim());
    if (imapPort == null || smtpPort == null) {
      setState(() => _error = 'Ports must be valid numbers.');
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    try {
      if (cacheConfig) {
        await BackendApiService.cacheEmailConfig(
          email: _emailController.text.trim(),
          imapHost: _imapHostController.text.trim(),
          imapPort: imapPort,
          imapSecure: _imapSecure,
          smtpHost: _smtpHostController.text.trim(),
          smtpPort: smtpPort,
          smtpSecure: _smtpSecure,
        );
      }
      if (!mounted) return;

      await context.read<AuthProvider>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
            imapHost: _imapHostController.text.trim(),
            imapPort: imapPort,
            imapSecure: _imapSecure,
            smtpHost: _smtpHostController.text.trim(),
            smtpPort: smtpPort,
            smtpSecure: _smtpSecure,
            authMethod: _resolvedSavedAuthMethod,
            smtpAuthMethod: _resolvedSavedAuthMethod,
          );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save this account. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _startHostedOauth(String provider) async {
    setState(() {
      _error = null;
      _isOauthLoading = true;
    });
    try {
      final redirectUri =
          kIsWeb
              ? Uri.base
                  .replace(path: '/', queryParameters: const {}, fragment: '')
                  .toString()
              : 'https://oauth.pankh.local/callback';
      final authUrl = await BackendApiService.fetchProviderAuthUrl(
        provider: provider,
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
          builder:
              (_) => OAuthLoginScreen(
                authUrl: authUrl,
                redirectUri: redirectUri,
                title: 'Continue with ${_providerLabel(provider)}',
              ),
        ),
      );
      if (!mounted || callbackUri == null) return;
      final token = callbackUri.queryParameters['token'];
      final callbackProvider = callbackUri.queryParameters['provider'];
      final email = callbackUri.queryParameters['email'];
      if (token == null || callbackProvider == null || email == null) {
        throw Exception('OAuth callback did not include session details.');
      }
      await context.read<AuthProvider>().loginWithOAuth(
            email: email,
            provider: callbackProvider,
            sessionToken: token,
            authMethod: _oauthAuthMethodForProvider(callbackProvider),
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

  String get _emailDomain {
    final parts = _emailController.text.trim().split('@');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  bool get _isManualStep =>
      _step == _LoginStep.manual || _step == _LoginStep.failed;

  bool get _shouldUseHostedAuth => _lookupResult?.hostedAuthAvailable == true;

  String? get _hostedAuthProvider => _lookupResult?.hostedAuthProvider;

  bool get _isAutodetectSelected => _selectedAuthMethod == 'Autodetect';

  bool get _shouldLaunchHostedAuth =>
      _isAutodetectSelected && _shouldUseHostedAuth;

  bool get _requiresPassword {
    if (_shouldLaunchHostedAuth) {
      return false;
    }
    switch (_selectedAuthMethod) {
      case 'No Authentication':
      case 'TLS Certificate':
        return false;
      default:
        return true;
    }
  }

  String get _resolvedSavedAuthMethod {
    if (_shouldLaunchHostedAuth) {
      return _oauthAuthMethodForProvider(_hostedAuthProvider);
    }
    if (_isAutodetectSelected) {
      return 'Normal password';
    }
    return _selectedAuthMethod;
  }

  void _openManualConfiguration() {
    final form = _identityFormKey.currentState;
    if (form == null || !form.validate()) return;
    _applyFallbackDefaults();
    setState(() {
      _error = null;
      _lookupResult = null;
      _selectedAuthMethod = 'Autodetect';
      _manualConfigStep = _ManualConfigStep.imap;
      _step = _LoginStep.manual;
    });
  }

  void _goBack() {
    setState(() {
      _error = null;
      if (_isManualStep && _manualConfigStep == _ManualConfigStep.smtp) {
        _manualConfigStep = _ManualConfigStep.imap;
        return;
      }
      if (_step == _LoginStep.found) {
        _selectedAuthMethod = 'Autodetect';
        _step = _LoginStep.identity;
        return;
      }
      if (_isManualStep) {
        _step = _lookupResult?.found == true ? _LoginStep.found : _LoginStep.identity;
      }
    });
  }

  void _openManualEditorFromPreview() {
    setState(() {
      _manualConfigStep = _ManualConfigStep.imap;
      _step = _LoginStep.manual;
    });
  }

  void _continueManualStepper() {
    final form = _manualFormKey.currentState;
    if (form == null || !form.validate()) return;

    if (_manualConfigStep == _ManualConfigStep.imap) {
      setState(() => _manualConfigStep = _ManualConfigStep.smtp);
      return;
    }

    if (_shouldLaunchHostedAuth) {
      _startHostedOauth(_hostedAuthProvider!);
      return;
    }

    _completeLogin(cacheConfig: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    final isMobile = width < 600;
    final horizontalPadding = isMobile ? 16.0 : 32.0;
    final cardMargin = isMobile ? 12.0 : 20.0;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: null,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(_backgroundImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      opacity: 0.12,
                      image: AssetImage('assets/logos/pankh-3d.png'),
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.all(cardMargin),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: (height - mediaQuery.padding.top - mediaQuery.padding.bottom - (cardMargin*2))),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 900,
                        minHeight: (height - mediaQuery.padding.top - mediaQuery.padding.bottom - (cardMargin*2)) * .75,
                      ),
                      child: Card(
                        elevation: 10,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: isMobile ? 24 : 32,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: isMobile ? 72 : 88,
                                  height: isMobile ? 72 : 88,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Image(
                                    image: AssetImage('assets/logos/pankh-3d.png'),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Pankh Account Setup',
                                textAlign: TextAlign.center,
                                style:
                                    isMobile
                                        ? theme.textTheme.headlineSmall
                                        : theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _titleForStep(),
                                textAlign: TextAlign.center,
                                style: (isMobile
                                        ? theme.textTheme.titleLarge
                                        : theme.textTheme.headlineSmall)
                                    ?.copyWith(color: theme.colorScheme.primary),
                              ),
                              const SizedBox(height: 24),
                              if (_error != null) ...[
                                _buildBanner(
                                  context,
                                  text: _error!,
                                  color: theme.colorScheme.errorContainer,
                                  foreground: theme.colorScheme.onErrorContainer,
                                  icon: Icons.error_outline,
                                ),
                                const SizedBox(height: 20),
                              ],
                              if (_step == _LoginStep.lookup) _buildLookupStep(context),
                              if (_step == _LoginStep.identity) _buildIdentityStep(context),
                              if (_step == _LoginStep.found) _buildFoundStep(context),
                              if (_isManualStep) _buildManualStep(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons({
    required List<Widget> children,
    MainAxisAlignment alignment = MainAxisAlignment.spaceBetween,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 520;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                SizedBox(width: double.infinity, child: children[index]),
                if (index != children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          mainAxisAlignment: alignment,
          children: children,
        );
      },
    );
  }

  Widget _buildResponsiveFields({
    required List<Widget> children,
    double breakpoint = 700,
    double spacing = 16,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < breakpoint ? 1 : 2;
        final itemWidth =
            columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              children
                  .map((child) => SizedBox(width: itemWidth, child: child))
                  .toList(),
        );
      },
    );
  }

  String _titleForStep() {
    switch (_step) {
      case _LoginStep.identity:
        return 'Add your name and email';
      case _LoginStep.lookup:
        return 'Looking up your email configuration';
      case _LoginStep.found:
        return 'We found your server settings';
      case _LoginStep.manual:
        return _manualConfigStep == _ManualConfigStep.imap
            ? 'Manual IMAP configuration'
            : 'Manual SMTP configuration';
      case _LoginStep.failed:
        return 'We could not find your server settings';
    }
  }

  Widget _buildIdentityStep(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _identityFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Email is required';
                  }
                  if (!trimmed.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildActionButtons(
                children: [
                  TextButton(
                    onPressed: _isOauthLoading ? null : _openManualConfiguration,
                    child: const Text('Manual configuration'),
                  ),
                  ElevatedButton(
                    onPressed: _startLookup,
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLookupStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBanner(
          context,
          text: 'Looking up configuration for ${_emailController.text.trim()}',
          color: Theme.of(context).colorScheme.primaryContainer,
          foreground: Theme.of(context).colorScheme.onPrimaryContainer,
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 28),
        const Center(
          child: SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: () {
              _lookupRequestId++;
              setState(() => _step = _LoginStep.identity);
            },
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Widget _buildFoundStep(BuildContext context) {
    final source = _sourceLabel(_lookupResult?.source);
    return Form(
      key: _manualFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBanner(
            context,
            text: 'Configuration found${source == null ? '' : ' in $source'}',
            color: Colors.green.shade100,
            foreground: Colors.green.shade900,
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 720;
              return Flex(
                direction: stacked ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: stacked ? 0 : 1,
                    child: _buildServerCard(
                      title: 'IMAP',
                      subtitle: 'Incoming server',
                      host: _imapHostController.text,
                      port: _imapPortController.text,
                      secure: _imapSecure,
                    ),
                  ),
                  SizedBox(width: stacked ? 0 : 16, height: stacked ? 16 : 0),
                  Expanded(
                    flex: stacked ? 0 : 1,
                    child: _buildServerCard(
                      title: 'SMTP',
                      subtitle: 'Outgoing server',
                      host: _smtpHostController.text,
                      port: _smtpPortController.text,
                      secure: _smtpSecure,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _selectedAuthMethod,
            decoration: const InputDecoration(
              labelText: 'Authentication method',
              border: OutlineInputBorder(),
            ),
            items:
                _setupAuthMethodOptions
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedAuthMethod = value);
            },
          ),
          const SizedBox(height: 20),
          if (_shouldLaunchHostedAuth)
            _buildBanner(
              context,
              text:
                  'This account supports ${_providerLabel(_hostedAuthProvider)} sign-in. Continue to authenticate with your email host.',
              color: Theme.of(context).colorScheme.primaryContainer,
              foreground: Theme.of(context).colorScheme.onPrimaryContainer,
              icon: Icons.verified_user_outlined,
            )
          else if (_requiresPassword)
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password / App password',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            )
          else if (_shouldUseHostedAuth)
            _buildBanner(
              context,
              text:
                  'Hosted sign-in is available for this account, but your selected authentication method will be used instead.',
              color: Theme.of(context).colorScheme.secondaryContainer,
              foreground: Theme.of(context).colorScheme.onSecondaryContainer,
              icon: Icons.info_outline,
            )
          else
            _buildBanner(
              context,
              text:
                  'The selected authentication method does not require a password during setup.',
              color: Theme.of(context).colorScheme.secondaryContainer,
              foreground: Theme.of(context).colorScheme.onSecondaryContainer,
              icon: Icons.info_outline,
            ),
          const SizedBox(height: 20),
          _buildActionButtons(
            children: [
              OutlinedButton(
                onPressed: _isSubmitting ? null : _goBack,
                child: const Text('Back'),
              ),
                      TextButton(
                        onPressed:
                            _isSubmitting
                                ? null
                                : _openManualEditorFromPreview,
                        child: const Text('Edit configuration'),
                      ),
              ElevatedButton(
                onPressed:
                    _isSubmitting || _isOauthLoading
                        ? null
                        : _shouldLaunchHostedAuth
                        ? () => _startHostedOauth(_hostedAuthProvider!)
                        : () => _completeLogin(cacheConfig: false),
                child:
                    _isSubmitting || _isOauthLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          _shouldLaunchHostedAuth
                              ? 'Continue with ${_providerLabel(_hostedAuthProvider)}'
                              : 'Continue',
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualStep(BuildContext context) {
    final failed = _step == _LoginStep.failed;

    return Form(
      key: _manualFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBanner(
            context,
            text:
                failed
                    ? 'Pankh failed to find settings for your email account.'
                    : _manualConfigStep == _ManualConfigStep.imap
                    ? 'Enter your incoming IMAP server details.'
                    : 'Enter your outgoing SMTP server details.',
            color:
                failed
                    ? const Color(0xFFFFF1BF)
                    : Theme.of(context).colorScheme.secondaryContainer,
            foreground:
                failed
                    ? const Color(0xFF6B5600)
                    : Theme.of(context).colorScheme.onSecondaryContainer,
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 20),
          _buildManualStepper(context),
          const SizedBox(height: 20),
          _buildActionButtons(
            children: [
              OutlinedButton(
                onPressed: _isSubmitting ? null : _goBack,
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed:
                    _isSubmitting || _isOauthLoading ? null : _continueManualStepper,
                child:
                    _isSubmitting || _isOauthLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          _manualConfigStep == _ManualConfigStep.imap
                              ? 'Next'
                              : _shouldLaunchHostedAuth
                              ? 'Continue with ${_providerLabel(_hostedAuthProvider)}'
                              : 'Continue',
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualStepper(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepIndicator(context),
        const SizedBox(height: 20),
        if (_manualConfigStep == _ManualConfigStep.imap)
          _buildConfigSection(
            context,
            title: 'IMAP Configuration',
            subtitle: 'Incoming mail server',
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedAuthMethod,
                items:
                    _setupAuthMethodOptions
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedAuthMethod = value);
                },
                decoration: const InputDecoration(
                  labelText: 'Authentication method',
                  border: OutlineInputBorder(),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: 'IMAP',
                items: const [
                  DropdownMenuItem(value: 'IMAP', child: Text('IMAP')),
                ],
                onChanged: null,
                decoration: const InputDecoration(
                  labelText: 'Protocol',
                  border: OutlineInputBorder(),
                ),
              ),
              TextFormField(
                controller: _imapHostController,
                decoration: const InputDecoration(
                  labelText: 'Hostname',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final host = value?.trim() ?? '';
                  if (host.isEmpty) {
                    return 'Hostname is required';
                  }
                  if (!RegExp(r'^[A-Za-z0-9.-]+$').hasMatch(host) ||
                      host.startsWith('.') ||
                      host.endsWith('.')) {
                    return 'Hostname is invalid';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _imapPortController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final port = int.tryParse(value?.trim() ?? '');
                  if (port == null || port < 1 || port > 65535) {
                    return 'Enter a valid port';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<bool>(
                initialValue: _imapSecure,
                decoration: const InputDecoration(
                  labelText: 'Connection security',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: true, child: Text('SSL/TLS')),
                  DropdownMenuItem(value: false, child: Text('STARTTLS / Plain')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _imapSecure = value);
                },
              ),
              TextFormField(
                initialValue: _emailController.text.trim(),
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_requiresPassword)
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password / App password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                )
              else
                _buildInlineInfo(
                  context,
                  _shouldLaunchHostedAuth
                      ? 'Autodetect will launch ${_providerLabel(_hostedAuthProvider)} sign-in after SMTP setup.'
                      : 'This authentication method does not require a password during setup.',
                ),
            ],
          )
        else
          _buildConfigSection(
            context,
            title: 'SMTP Configuration',
            subtitle: 'Outgoing mail server',
            children: [
              TextFormField(
                controller: _smtpHostController,
                decoration: const InputDecoration(
                  labelText: 'SMTP hostname',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value?.trim() ?? '').isEmpty) {
                    return 'SMTP hostname is required';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _smtpPortController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'SMTP port',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final port = int.tryParse(value?.trim() ?? '');
                  if (port == null || port < 1 || port > 65535) {
                    return 'Invalid port';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<bool>(
                initialValue: _smtpSecure,
                decoration: const InputDecoration(
                  labelText: 'SMTP security',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: true, child: Text('SSL/TLS')),
                  DropdownMenuItem(value: false, child: Text('STARTTLS / Plain')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _smtpSecure = value);
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    final currentIndex = _manualConfigStep == _ManualConfigStep.imap ? 0 : 1;
    return Row(
      children: [
        Expanded(
          child: _buildStepChip(
            context,
            label: '1. IMAP',
            active: currentIndex == 0,
            completed: currentIndex > 0,
          ),
        ),
        Container(
          width: 24,
          height: 2,
          color: Theme.of(context).colorScheme.outlineVariant,
          margin: const EdgeInsets.symmetric(horizontal: 8),
        ),
        Expanded(
          child: _buildStepChip(
            context,
            label: '2. SMTP',
            active: currentIndex == 1,
            completed: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStepChip(
    BuildContext context, {
    required String label,
    required bool active,
    required bool completed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final background =
        active
            ? scheme.primaryContainer
            : completed
            ? Colors.green.shade100
            : Theme.of(context).cardColor;
    final foreground =
        active
            ? scheme.onPrimaryContainer
            : completed
            ? Colors.green.shade900
            : Theme.of(context).textTheme.bodyMedium?.color ?? scheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildConfigSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _buildResponsiveFields(
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(
    BuildContext context, {
    required String text,
    required Color color,
    required Color foreground,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineInfo(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildServerCard({
    required String title,
    required String subtitle,
    required String host,
    required String port,
    required bool secure,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle),
          const SizedBox(height: 16),
          Text('Hostname: $host'),
          const SizedBox(height: 6),
          Text('Port: $port'),
          const SizedBox(height: 6),
          Text('Security: ${secure ? 'SSL/TLS' : 'STARTTLS / Plain'}'),
          const SizedBox(height: 6),
          Text('Username: ${_emailController.text.trim()}'),
        ],
      ),
    );
  }

  String? _sourceLabel(String? source) {
    switch (source) {
      case 'cache':
        return 'Pankh cache';
      case 'ispdb':
        return 'Mozilla ISPDB';
      case 'domain-autoconfig':
        return 'domain autoconfig';
      case 'manual':
        return 'saved manual settings';
      default:
        return null;
    }
  }

  String _providerLabel(String? provider) {
    switch (provider) {
      case 'google':
        return 'Google';
      case 'microsoft':
        return 'Microsoft';
      case 'yahoo':
        return 'Yahoo';
      default:
        return 'your provider';
    }
  }

  String _oauthAuthMethodForProvider(String? provider) {
    switch (provider) {
      case 'microsoft':
        return 'Exchange / OAuth2';
      case 'google':
      case 'yahoo':
      default:
        return 'OAuth2';
    }
  }
}
