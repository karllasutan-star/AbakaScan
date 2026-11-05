import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../providers/app_providers.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.verifyEmail(
      otp: _otpController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            authProvider.verificationMessage ?? 'Email verified successfully.',
          ),
        ),
      );

    Navigator.of(context).pop(true);
  }

  Future<void> _resendCode() async {
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.resendVerification();

    if (!mounted) {
      return;
    }

    if (!success) {
      return;
    }

    _otpController.clear();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            authProvider.verificationMessage ??
                'A new verification code was sent.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final email = authProvider.pendingVerificationEmail ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= AppBreakpoints.desktop;

          if (desktop) {
            return Row(
              children: [
                const Expanded(flex: 11, child: _VerificationHero()),
                Expanded(
                  flex: 10,
                  child: _VerificationContent(
                    formKey: _formKey,
                    otpController: _otpController,
                    email: email,
                    onVerify: _verifyEmail,
                    onResend: _resendCode,
                  ),
                ),
              ],
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  const SizedBox(height: 250, child: _VerificationHero()),
                  Transform.translate(
                    offset: const Offset(0, -35),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _VerificationCard(
                        formKey: _formKey,
                        otpController: _otpController,
                        email: email,
                        onVerify: _verifyEmail,
                        onResend: _resendCode,
                        compact: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VerificationContent extends StatelessWidget {
  const _VerificationContent({
    required this.formKey,
    required this.otpController,
    required this.email,
    required this.onVerify,
    required this.onResend,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController otpController;
  final String email;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 44),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _VerificationCard(
              formKey: formKey,
              otpController: otpController,
              email: email,
              onVerify: onVerify,
              onResend: onResend,
              compact: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.formKey,
    required this.otpController,
    required this.email,
    required this.onVerify,
    required this.onResend,
    required this.compact,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController otpController;
  final String email;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final busy =
        authProvider.verificationLoading ||
        authProvider.resendVerificationLoading;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 22 : 34),
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
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 30,
                color: AppColors.primaryDark,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Verify your email',
              textAlign: TextAlign.center,
              style: AppTypography.pageTitle.copyWith(
                fontSize: compact ? 28 : 34,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'We sent a 6-digit verification code to',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary,
            ),

            const SizedBox(height: 5),

            Text(
              email.isEmpty ? 'your email address' : email,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),

            const SizedBox(height: 28),

            TextFormField(
              controller: otpController,
              enabled: !busy,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: AppTypography.pageTitle.copyWith(
                fontSize: 24,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                prefixIcon: const Icon(Icons.lock_clock_outlined),
                filled: true,
                fillColor: AppColors.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryDark,
                    width: 1.5,
                  ),
                ),
              ),
              validator: (value) {
                final otp = value?.trim() ?? '';

                if (otp.isEmpty) {
                  return 'Verification code is required.';
                }

                if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                  return 'Enter the 6-digit verification code.';
                }

                return null;
              },
              onFieldSubmitted: (_) {
                if (!busy) {
                  onVerify();
                }
              },
            ),

            if (authProvider.verificationError != null) ...[
              const SizedBox(height: 14),
              _VerificationMessage(
                text: authProvider.verificationError!,
                error: true,
              ),
            ],

            if (authProvider.verificationMessage != null &&
                authProvider.verificationError == null) ...[
              const SizedBox(height: 14),
              _VerificationMessage(
                text: authProvider.verificationMessage!,
                error: false,
              ),
            ],

            const SizedBox(height: 22),

            SizedBox(
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
                onPressed: busy ? null : onVerify,
                child: authProvider.verificationLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Verify Email'),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: Text(
                    "Didn't receive the code?",
                    style: AppTypography.bodySecondary,
                  ),
                ),
                TextButton(
                  onPressed: busy ? null : onResend,
                  child: authProvider.resendVerificationLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resend Code'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            TextButton.icon(
              onPressed: busy
                  ? null
                  : () {
                      Navigator.of(context).pop(false);
                    },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Registration'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationMessage extends StatelessWidget {
  const _VerificationMessage({required this.text, required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error
        ? Theme.of(context).colorScheme.error
        : AppColors.primaryDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text, style: AppTypography.body.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _VerificationHero extends StatelessWidget {
  const _VerificationHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/abakascan_auth_hero.png', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xF20B392B), Color(0xC80B392B), Color(0x650B392B)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.eco_outlined, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'ABAKASCAN',
                    style: AppTypography.cardTitle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'One more step.',
                style: AppTypography.pageTitle.copyWith(
                  color: Colors.white,
                  fontSize: 42,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Verify your email address to secure your ABAKASCAN account.',
                style: AppTypography.bodySecondary.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(width: 48, height: 3, color: AppColors.fiberBeige),
            ],
          ),
        ),
      ],
    );
  }
}
