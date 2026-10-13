import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';

enum _AuthMode { login, register, forgotPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.startInRegisterMode = false});

  final bool startInRegisterMode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _forgotPasswordFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _fullNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otherRoleController = TextEditingController();

  final _forgotPasswordEmailController = TextEditingController();

  _AuthMode _authMode = _AuthMode.login;

  String? _selectedStakeholderRole;

  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;

  static const _stakeholderRoles = <String>[
    'Farmer',
    'Fiber Processor',
    'Cooperative',
    'Buyer',
    'Agricultural Researcher',
    'Others',
  ];

  @override
  void initState() {
    super.initState();

    _authMode = widget.startInRegisterMode
        ? _AuthMode.register
        : _AuthMode.login;
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();

    _fullNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otherRoleController.dispose();

    _forgotPasswordEmailController.dispose();

    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();

    authProvider.clearLoginError();
    authProvider.clearRegisterError();
    authProvider.clearRegistrationMessage();

    setState(() {
      _authMode = mode;
    });
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();

    if (!(_loginFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      identifier: _loginEmailController.text.trim(),
      password: _loginPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authProvider.isAdmin
              ? 'Administrator login successful.'
              : 'Login successful.',
        ),
      ),
    );

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitRegister() async {
    FocusScope.of(context).unfocus();

    if (!(_registerFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final stakeholderRole = _convertStakeholderRole(_selectedStakeholderRole);

    if (stakeholderRole == null) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      fullName: _fullNameController.text.trim(),
      email: _registerEmailController.text.trim(),
      password: _registerPasswordController.text,
      stakeholderRole: stakeholderRole,
      customRole: stakeholderRole == StakeholderRole.others
          ? _otherRoleController.text.trim()
          : null,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      return;
    }

    _registerFormKey.currentState?.reset();

    _fullNameController.clear();
    _registerEmailController.clear();
    _registerPasswordController.clear();
    _confirmPasswordController.clear();
    _otherRoleController.clear();

    setState(() {
      _selectedStakeholderRole = null;
      _authMode = _AuthMode.login;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration successful. Please log in.')),
    );
  }

  void _submitForgotPassword() {
    FocusScope.of(context).unfocus();

    if (!(_forgotPasswordFormKey.currentState?.validate() ?? false)) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Password recovery is awaiting backend integration.'),
        ),
      );
  }

  StakeholderRole? _convertStakeholderRole(String? role) {
    switch (role) {
      case 'Farmer':
        return StakeholderRole.farmer;

      case 'Fiber Processor':
        return StakeholderRole.fiberProcessor;

      case 'Cooperative':
        return StakeholderRole.cooperative;

      case 'Buyer':
        return StakeholderRole.buyer;

      case 'Agricultural Researcher':
        return StakeholderRole.agriculturalResearcher;

      case 'Others':
        return StakeholderRole.others;

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= AppBreakpoints.desktop;

          if (desktop) {
            return _DesktopAuthLayout(
              authMode: _authMode,
              loginFormKey: _loginFormKey,
              registerFormKey: _registerFormKey,
              forgotPasswordFormKey: _forgotPasswordFormKey,
              loginEmailController: _loginEmailController,
              loginPasswordController: _loginPasswordController,
              fullNameController: _fullNameController,
              registerEmailController: _registerEmailController,
              registerPasswordController: _registerPasswordController,
              confirmPasswordController: _confirmPasswordController,
              otherRoleController: _otherRoleController,
              forgotPasswordEmailController: _forgotPasswordEmailController,
              selectedStakeholderRole: _selectedStakeholderRole,
              stakeholderRoles: _stakeholderRoles,
              obscureLoginPassword: _obscureLoginPassword,
              obscureRegisterPassword: _obscureRegisterPassword,
              obscureConfirmPassword: _obscureConfirmPassword,
              onModeChanged: _switchMode,
              onLogin: _submitLogin,
              onRegister: _submitRegister,
              onForgotPassword: _submitForgotPassword,
              onRoleChanged: (value) {
                setState(() {
                  _selectedStakeholderRole = value;
                });
              },
              onToggleLoginPassword: () {
                setState(() {
                  _obscureLoginPassword = !_obscureLoginPassword;
                });
              },
              onToggleRegisterPassword: () {
                setState(() {
                  _obscureRegisterPassword = !_obscureRegisterPassword;
                });
              },
              onToggleConfirmPassword: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            );
          }

          return _MobileAuthLayout(
            authMode: _authMode,
            loginFormKey: _loginFormKey,
            registerFormKey: _registerFormKey,
            forgotPasswordFormKey: _forgotPasswordFormKey,
            loginEmailController: _loginEmailController,
            loginPasswordController: _loginPasswordController,
            fullNameController: _fullNameController,
            registerEmailController: _registerEmailController,
            registerPasswordController: _registerPasswordController,
            confirmPasswordController: _confirmPasswordController,
            otherRoleController: _otherRoleController,
            forgotPasswordEmailController: _forgotPasswordEmailController,
            selectedStakeholderRole: _selectedStakeholderRole,
            stakeholderRoles: _stakeholderRoles,
            obscureLoginPassword: _obscureLoginPassword,
            obscureRegisterPassword: _obscureRegisterPassword,
            obscureConfirmPassword: _obscureConfirmPassword,
            onModeChanged: _switchMode,
            onLogin: _submitLogin,
            onRegister: _submitRegister,
            onForgotPassword: _submitForgotPassword,
            onRoleChanged: (value) {
              setState(() {
                _selectedStakeholderRole = value;
              });
            },
            onToggleLoginPassword: () {
              setState(() {
                _obscureLoginPassword = !_obscureLoginPassword;
              });
            },
            onToggleRegisterPassword: () {
              setState(() {
                _obscureRegisterPassword = !_obscureRegisterPassword;
              });
            },
            onToggleConfirmPassword: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// DESKTOP
// ============================================================

class _DesktopAuthLayout extends StatelessWidget {
  const _DesktopAuthLayout({
    required this.authMode,
    required this.loginFormKey,
    required this.registerFormKey,
    required this.forgotPasswordFormKey,
    required this.loginEmailController,
    required this.loginPasswordController,
    required this.fullNameController,
    required this.registerEmailController,
    required this.registerPasswordController,
    required this.confirmPasswordController,
    required this.otherRoleController,
    required this.forgotPasswordEmailController,
    required this.selectedStakeholderRole,
    required this.stakeholderRoles,
    required this.obscureLoginPassword,
    required this.obscureRegisterPassword,
    required this.obscureConfirmPassword,
    required this.onModeChanged,
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
    required this.onRoleChanged,
    required this.onToggleLoginPassword,
    required this.onToggleRegisterPassword,
    required this.onToggleConfirmPassword,
  });

  final _AuthMode authMode;

  final GlobalKey<FormState> loginFormKey;
  final GlobalKey<FormState> registerFormKey;
  final GlobalKey<FormState> forgotPasswordFormKey;

  final TextEditingController loginEmailController;
  final TextEditingController loginPasswordController;
  final TextEditingController fullNameController;
  final TextEditingController registerEmailController;
  final TextEditingController registerPasswordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController otherRoleController;
  final TextEditingController forgotPasswordEmailController;

  final String? selectedStakeholderRole;
  final List<String> stakeholderRoles;

  final bool obscureLoginPassword;
  final bool obscureRegisterPassword;
  final bool obscureConfirmPassword;

  final ValueChanged<_AuthMode> onModeChanged;

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  final ValueChanged<String?> onRoleChanged;

  final VoidCallback onToggleLoginPassword;
  final VoidCallback onToggleRegisterPassword;
  final VoidCallback onToggleConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 11, child: _DesktopHeroPanel()),

        Expanded(
          flex: 10,
          child: Container(
            color: AppColors.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 44),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _AuthCard(
                    authMode: authMode,
                    loginFormKey: loginFormKey,
                    registerFormKey: registerFormKey,
                    forgotPasswordFormKey: forgotPasswordFormKey,
                    loginEmailController: loginEmailController,
                    loginPasswordController: loginPasswordController,
                    fullNameController: fullNameController,
                    registerEmailController: registerEmailController,
                    registerPasswordController: registerPasswordController,
                    confirmPasswordController: confirmPasswordController,
                    otherRoleController: otherRoleController,
                    forgotPasswordEmailController:
                        forgotPasswordEmailController,
                    selectedStakeholderRole: selectedStakeholderRole,
                    stakeholderRoles: stakeholderRoles,
                    obscureLoginPassword: obscureLoginPassword,
                    obscureRegisterPassword: obscureRegisterPassword,
                    obscureConfirmPassword: obscureConfirmPassword,
                    onModeChanged: onModeChanged,
                    onLogin: onLogin,
                    onRegister: onRegister,
                    onForgotPassword: onForgotPassword,
                    onRoleChanged: onRoleChanged,
                    onToggleLoginPassword: onToggleLoginPassword,
                    onToggleRegisterPassword: onToggleRegisterPassword,
                    onToggleConfirmPassword: onToggleConfirmPassword,
                    compact: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopHeroPanel extends StatelessWidget {
  const _DesktopHeroPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/abakascan_auth_hero.png', fit: BoxFit.cover),

        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xF20B392B), Color(0xC80B392B), Color(0x520B392B)],
            ),
          ),
        ),

        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _GoldFiberPainter()),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(62, 56, 52, 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Brand(),

              const Spacer(),

              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'See the quality\nin every '),
                    TextSpan(
                      text: 'fiber.',
                      style: TextStyle(color: AppColors.fiberBeige),
                    ),
                  ],
                ),
                style: AppTypography.pageTitle.copyWith(
                  color: Colors.white,
                  fontSize: 53,
                  height: 1.05,
                ),
              ),

              const SizedBox(height: 22),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Text(
                  'Image-based abaca fiber grade classification for a clearer digital workflow.',
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.6,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Container(width: 42, height: 3, color: AppColors.fiberBeige),

              const SizedBox(height: 48),

              const Row(
                children: [
                  Expanded(
                    child: _HeroFeature(
                      icon: Icons.image_search_outlined,
                      title: 'IMAGE\nPROCESSING',
                    ),
                  ),
                  Expanded(
                    child: _HeroFeature(
                      icon: Icons.memory_outlined,
                      title: 'MACHINE\nLEARNING',
                    ),
                  ),
                  Expanded(
                    child: _HeroFeature(
                      icon: Icons.eco_outlined,
                      title: 'FIBER\nCLASSIFICATION',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// MOBILE
// ============================================================

class _MobileAuthLayout extends StatelessWidget {
  const _MobileAuthLayout({
    required this.authMode,
    required this.loginFormKey,
    required this.registerFormKey,
    required this.forgotPasswordFormKey,
    required this.loginEmailController,
    required this.loginPasswordController,
    required this.fullNameController,
    required this.registerEmailController,
    required this.registerPasswordController,
    required this.confirmPasswordController,
    required this.otherRoleController,
    required this.forgotPasswordEmailController,
    required this.selectedStakeholderRole,
    required this.stakeholderRoles,
    required this.obscureLoginPassword,
    required this.obscureRegisterPassword,
    required this.obscureConfirmPassword,
    required this.onModeChanged,
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
    required this.onRoleChanged,
    required this.onToggleLoginPassword,
    required this.onToggleRegisterPassword,
    required this.onToggleConfirmPassword,
  });

  final _AuthMode authMode;

  final GlobalKey<FormState> loginFormKey;
  final GlobalKey<FormState> registerFormKey;
  final GlobalKey<FormState> forgotPasswordFormKey;

  final TextEditingController loginEmailController;
  final TextEditingController loginPasswordController;
  final TextEditingController fullNameController;
  final TextEditingController registerEmailController;
  final TextEditingController registerPasswordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController otherRoleController;
  final TextEditingController forgotPasswordEmailController;

  final String? selectedStakeholderRole;
  final List<String> stakeholderRoles;

  final bool obscureLoginPassword;
  final bool obscureRegisterPassword;
  final bool obscureConfirmPassword;

  final ValueChanged<_AuthMode> onModeChanged;

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  final ValueChanged<String?> onRoleChanged;

  final VoidCallback onToggleLoginPassword;
  final VoidCallback onToggleRegisterPassword;
  final VoidCallback onToggleConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            const _MobileHero(),

            Transform.translate(
              offset: const Offset(0, -66),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _AuthCard(
                  authMode: authMode,
                  loginFormKey: loginFormKey,
                  registerFormKey: registerFormKey,
                  forgotPasswordFormKey: forgotPasswordFormKey,
                  loginEmailController: loginEmailController,
                  loginPasswordController: loginPasswordController,
                  fullNameController: fullNameController,
                  registerEmailController: registerEmailController,
                  registerPasswordController: registerPasswordController,
                  confirmPasswordController: confirmPasswordController,
                  otherRoleController: otherRoleController,
                  forgotPasswordEmailController: forgotPasswordEmailController,
                  selectedStakeholderRole: selectedStakeholderRole,
                  stakeholderRoles: stakeholderRoles,
                  obscureLoginPassword: obscureLoginPassword,
                  obscureRegisterPassword: obscureRegisterPassword,
                  obscureConfirmPassword: obscureConfirmPassword,
                  onModeChanged: onModeChanged,
                  onLogin: onLogin,
                  onRegister: onRegister,
                  onForgotPassword: onForgotPassword,
                  onRoleChanged: onRoleChanged,
                  onToggleLoginPassword: onToggleLoginPassword,
                  onToggleRegisterPassword: onToggleRegisterPassword,
                  onToggleConfirmPassword: onToggleConfirmPassword,
                  compact: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 455,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/abakascan_auth_hero.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
          ),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xE90A382A),
                  Color(0xB80A382A),
                  Color(0x470A382A),
                ],
              ),
            ),
          ),

          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _GoldFiberPainter()),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 92),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Brand(),

                const SizedBox(height: 52),

                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'See the quality\nin every '),
                      TextSpan(
                        text: 'fiber.',
                        style: TextStyle(color: AppColors.fiberBeige),
                      ),
                    ],
                  ),
                  style: AppTypography.pageTitle.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                    height: 1.04,
                  ),
                ),

                const SizedBox(height: 17),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    'Image-based abaca fiber grade classification for a clearer digital workflow.',
                    style: AppTypography.bodySecondary.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                      height: 1.48,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Container(width: 48, height: 3, color: AppColors.fiberBeige),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AUTH CARD
// ============================================================

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.authMode,
    required this.loginFormKey,
    required this.registerFormKey,
    required this.forgotPasswordFormKey,
    required this.loginEmailController,
    required this.loginPasswordController,
    required this.fullNameController,
    required this.registerEmailController,
    required this.registerPasswordController,
    required this.confirmPasswordController,
    required this.otherRoleController,
    required this.forgotPasswordEmailController,
    required this.selectedStakeholderRole,
    required this.stakeholderRoles,
    required this.obscureLoginPassword,
    required this.obscureRegisterPassword,
    required this.obscureConfirmPassword,
    required this.onModeChanged,
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
    required this.onRoleChanged,
    required this.onToggleLoginPassword,
    required this.onToggleRegisterPassword,
    required this.onToggleConfirmPassword,
    required this.compact,
  });

  final _AuthMode authMode;

  final GlobalKey<FormState> loginFormKey;
  final GlobalKey<FormState> registerFormKey;
  final GlobalKey<FormState> forgotPasswordFormKey;

  final TextEditingController loginEmailController;
  final TextEditingController loginPasswordController;
  final TextEditingController fullNameController;
  final TextEditingController registerEmailController;
  final TextEditingController registerPasswordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController otherRoleController;
  final TextEditingController forgotPasswordEmailController;

  final String? selectedStakeholderRole;
  final List<String> stakeholderRoles;

  final bool obscureLoginPassword;
  final bool obscureRegisterPassword;
  final bool obscureConfirmPassword;

  final ValueChanged<_AuthMode> onModeChanged;

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  final ValueChanged<String?> onRoleChanged;

  final VoidCallback onToggleLoginPassword;
  final VoidCallback onToggleRegisterPassword;
  final VoidCallback onToggleConfirmPassword;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(compact ? 28 : 24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          if (authMode != _AuthMode.forgotPassword)
            _AuthTabs(authMode: authMode, onModeChanged: onModeChanged)
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  onModeChanged(_AuthMode.login);
                },
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Log In'),
              ),
            ),

          const SizedBox(height: 30),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (authMode) {
              _AuthMode.login => _LoginForm(
                key: const ValueKey('login'),
                formKey: loginFormKey,
                emailController: loginEmailController,
                passwordController: loginPasswordController,
                obscurePassword: obscureLoginPassword,
                compact: compact,
                onTogglePassword: onToggleLoginPassword,
                onLogin: onLogin,
                onForgotPassword: () {
                  onModeChanged(_AuthMode.forgotPassword);
                },
              ),

              _AuthMode.register => _RegisterForm(
                key: const ValueKey('register'),
                formKey: registerFormKey,
                fullNameController: fullNameController,
                emailController: registerEmailController,
                passwordController: registerPasswordController,
                confirmPasswordController: confirmPasswordController,
                otherRoleController: otherRoleController,
                selectedStakeholderRole: selectedStakeholderRole,
                stakeholderRoles: stakeholderRoles,
                obscurePassword: obscureRegisterPassword,
                obscureConfirmPassword: obscureConfirmPassword,
                compact: compact,
                onRoleChanged: onRoleChanged,
                onTogglePassword: onToggleRegisterPassword,
                onToggleConfirmPassword: onToggleConfirmPassword,
                onRegister: onRegister,
              ),

              _AuthMode.forgotPassword => _ForgotPasswordForm(
                key: const ValueKey('forgot'),
                formKey: forgotPasswordFormKey,
                emailController: forgotPasswordEmailController,
                compact: compact,
                onSubmit: onForgotPassword,
              ),
            },
          ),

          if (authMode == _AuthMode.login) ...[
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 18),
            const _SecurityNote(),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// CENTERED LOGIN / REGISTER
// ============================================================

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.authMode, required this.onModeChanged});

  final _AuthMode authMode;
  final ValueChanged<_AuthMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthTabButton(
              text: 'Log In',
              selected: authMode == _AuthMode.login,
              onTap: () {
                onModeChanged(_AuthMode.login);
              },
            ),
          ),

          Expanded(
            child: _AuthTabButton(
              text: 'Register',
              selected: authMode == _AuthMode.register,
              onTap: () {
                onModeChanged(_AuthMode.register);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryDark : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.compact,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;

  final TextEditingController emailController;
  final TextEditingController passwordController;

  final bool obscurePassword;
  final bool compact;

  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Form(
      key: formKey,
      child: AutofillGroup(
        child: Column(
          children: [
            Text(
              'Welcome back',
              textAlign: TextAlign.center,
              style: AppTypography.pageTitle.copyWith(
                fontSize: compact ? 29 : 34,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Log in to continue to your ABAKASCAN workspace.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary,
            ),

            const SizedBox(height: 28),

            TextFormField(
              controller: emailController,
              enabled: !authProvider.loginLoading,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              decoration: _authDecoration(
                hint: 'Email or Username',
                prefix: Icons.mail_outline_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email or username is required.';
                }

                return null;
              },
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: passwordController,
              enabled: !authProvider.loginLoading,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              decoration: _authDecoration(
                hint: 'Password',
                prefix: Icons.lock_outline,
                suffix: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required.';
                }

                return null;
              },
            ),

            const SizedBox(height: 5),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: authProvider.loginLoading ? null : onForgotPassword,
                child: const Text('Forgot Password?'),
              ),
            ),

            if (authProvider.loginError != null) ...[
              const SizedBox(height: 8),
              _MessageBox(text: authProvider.loginError!, error: true),
            ],

            if (authProvider.sessionMessage != null) ...[
              const SizedBox(height: 8),
              _MessageBox(text: authProvider.sessionMessage!, error: true),
            ],

            const SizedBox(height: 16),

            _AuthButton(
              label: 'Log In',
              loading: authProvider.loginLoading,
              onPressed: authProvider.loginLoading ? null : onLogin,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// REGISTER
// ============================================================

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    super.key,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.otherRoleController,
    required this.selectedStakeholderRole,
    required this.stakeholderRoles,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.compact,
    required this.onRoleChanged,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onRegister,
  });

  final GlobalKey<FormState> formKey;

  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController otherRoleController;

  final String? selectedStakeholderRole;
  final List<String> stakeholderRoles;

  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool compact;

  final ValueChanged<String?> onRoleChanged;

  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Form(
      key: formKey,
      child: Column(
        children: [
          Text(
            'Create account',
            style: AppTypography.pageTitle.copyWith(
              fontSize: compact ? 28 : 33,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Create your ABAKASCAN workspace.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary,
          ),

          const SizedBox(height: 25),

          TextFormField(
            controller: fullNameController,
            enabled: !authProvider.registerLoading,
            textInputAction: TextInputAction.next,
            decoration: _authDecoration(
              hint: 'Full Name',
              prefix: Icons.person_outline,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full name is required.';
              }

              return null;
            },
          ),

          const SizedBox(height: 13),

          TextFormField(
            controller: emailController,
            enabled: !authProvider.registerLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _authDecoration(
              hint: 'Email Address',
              prefix: Icons.mail_outline,
            ),
            validator: (value) {
              final email = value?.trim() ?? '';

              if (email.isEmpty) {
                return 'Email is required.';
              }

              if (!email.contains('@')) {
                return 'Enter a valid email address.';
              }

              return null;
            },
          ),

          const SizedBox(height: 13),

          DropdownButtonFormField<String>(
            initialValue: selectedStakeholderRole,
            isExpanded: true,
            decoration: _authDecoration(
              hint: 'Select your role',
              prefix: Icons.badge_outlined,
            ),
            items: stakeholderRoles
                .map(
                  (role) =>
                      DropdownMenuItem<String>(value: role, child: Text(role)),
                )
                .toList(),
            onChanged: authProvider.registerLoading ? null : onRoleChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your role.';
              }

              return null;
            },
          ),

          if (selectedStakeholderRole == 'Others') ...[
            const SizedBox(height: 13),

            TextFormField(
              controller: otherRoleController,
              enabled: !authProvider.registerLoading,
              decoration: _authDecoration(
                hint: 'Specify your role',
                prefix: Icons.edit_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please specify your role.';
                }

                return null;
              },
            ),
          ],

          const SizedBox(height: 13),

          TextFormField(
            controller: passwordController,
            enabled: !authProvider.registerLoading,
            obscureText: obscurePassword,
            decoration: _authDecoration(
              hint: 'Password',
              prefix: Icons.lock_outline,
              suffix: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required.';
              }

              if (value.length < 8) {
                return 'Use at least 8 characters.';
              }

              return null;
            },
          ),

          const SizedBox(height: 13),

          TextFormField(
            controller: confirmPasswordController,
            enabled: !authProvider.registerLoading,
            obscureText: obscureConfirmPassword,
            decoration: _authDecoration(
              hint: 'Confirm Password',
              prefix: Icons.lock_outline,
              suffix: IconButton(
                onPressed: onToggleConfirmPassword,
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password.';
              }

              if (value != passwordController.text) {
                return 'Passwords do not match.';
              }

              return null;
            },
          ),

          if (authProvider.registerError != null) ...[
            const SizedBox(height: 13),

            _MessageBox(text: authProvider.registerError!, error: true),
          ],

          const SizedBox(height: 20),

          _AuthButton(
            label: 'Create Account',
            loading: authProvider.registerLoading,
            onPressed: authProvider.registerLoading ? null : onRegister,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FORGOT PASSWORD
// ============================================================

class _ForgotPasswordForm extends StatelessWidget {
  const _ForgotPasswordForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.compact,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;

  final bool compact;

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_outlined,
              color: AppColors.primaryDark,
              size: 30,
            ),
          ),

          const SizedBox(height: 17),

          Text(
            'Forgot password?',
            style: AppTypography.pageTitle.copyWith(
              fontSize: compact ? 27 : 32,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Enter the email address associated with your ABAKASCAN account.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary,
          ),

          const SizedBox(height: 26),

          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _authDecoration(
              hint: 'Email Address',
              prefix: Icons.mail_outline,
            ),
            validator: (value) {
              final email = value?.trim() ?? '';

              if (email.isEmpty) {
                return 'Email address is required.';
              }

              if (!email.contains('@')) {
                return 'Enter a valid email address.';
              }

              return null;
            },
          ),

          const SizedBox(height: 20),

          _AuthButton(
            label: 'Send Recovery Link',
            loading: false,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SHARED AUTH WIDGETS
// ============================================================

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        onPressed: onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label),

                  const SizedBox(width: 12),

                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: Colors.white,
            size: 19,
          ),
        ),

        const SizedBox(width: 12),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Secure account access', style: AppTypography.cardTitle),

              SizedBox(height: 3),

              Text(
                'Sign in to access your ABAKASCAN workspace and saved analyses.',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.text, required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.error : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(text, style: AppTypography.caption.copyWith(color: color)),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.fiberBeige),
          ),
          child: Icon(icon, color: AppColors.fiberBeige, size: 21),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: AppTypography.label.copyWith(
            color: Colors.white,
            fontSize: 9,
            height: 1.5,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// BRAND
// ============================================================

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.eco_outlined, size: 28, color: AppColors.fiberBeige),

        const SizedBox(width: 10),

        Text(
          'ABAKASCAN',
          style: AppTypography.label.copyWith(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.6,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// INPUT STYLE
// ============================================================

InputDecoration _authDecoration({
  required String hint,
  required IconData prefix,
  Widget? suffix,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: const BorderSide(color: AppColors.border),
  );

  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(prefix),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
  );
}

// ============================================================
// GOLD FIBER LINES
// ============================================================

class _GoldFiberPainter extends CustomPainter {
  const _GoldFiberPainter();

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < 11; index++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = index % 3 == 0 ? 1.15 : 0.7
        ..color = AppColors.fiberBeige.withValues(alpha: 0.33);

      final y = size.height * (0.32 + index * 0.018);

      final path = Path()
        ..moveTo(-20, y)
        ..cubicTo(
          size.width * 0.28,
          y + size.height * 0.20,
          size.width * 0.70,
          y - size.height * 0.18,
          size.width + 30,
          y + size.height * 0.04,
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
