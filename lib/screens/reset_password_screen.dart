import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../providers/app_providers.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _submitReset() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.resetPassword(
      otp: _otpController.text.trim(),
      newPassword: _newPasswordController.text,
    );

    if (!mounted || !success) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Password reset successfully.')),
      );

    Navigator.of(context).pop(true);
  }

  Future<void> _resendCode() async {
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();

    final email = authProvider.pendingPasswordResetEmail?.trim() ?? '';

    if (email.isEmpty) {
      return;
    }

    final success = await authProvider.forgotPassword(email: email);

    if (!mounted || !success) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('A new password reset code was sent.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final email = authProvider.pendingPasswordResetEmail?.trim() ?? '';

    final compact = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: authProvider.resetPasswordLoading
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Reset Password', style: AppTypography.cardTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 32,
            vertical: compact ? 24 : 42,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 24 : 34),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _ResetIcon(),

                        const SizedBox(height: 20),

                        Text(
                          'Create a new password',
                          textAlign: TextAlign.center,
                          style: AppTypography.pageTitle.copyWith(
                            fontSize: compact ? 27 : 32,
                          ),
                        ),

                        const SizedBox(height: 9),

                        Text(
                          email.isEmpty
                              ? 'Enter the verification code sent to your email.'
                              : 'Enter the 6-digit code sent to $email.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySecondary,
                        ),

                        const SizedBox(height: 30),

                        TextFormField(
                          controller: _otpController,
                          enabled: !authProvider.resetPasswordLoading,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _decoration(
                            hint: '6-Digit Reset Code',
                            prefix: Icons.password_rounded,
                          ).copyWith(counterText: ''),
                          validator: (value) {
                            final code = value?.trim() ?? '';

                            if (code.isEmpty) {
                              return 'Reset code is required.';
                            }

                            if (code.length != 6) {
                              return 'Enter the complete 6-digit code.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _newPasswordController,
                          enabled: !authProvider.resetPasswordLoading,
                          obscureText: _obscureNewPassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: _decoration(
                            hint: 'New Password',
                            prefix: Icons.lock_outline,
                            suffix: IconButton(
                              tooltip: _obscureNewPassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                              icon: Icon(
                                _obscureNewPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'New password is required.';
                            }

                            if (value.length < 8) {
                              return 'Use at least 8 characters.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _confirmPasswordController,
                          enabled: !authProvider.resetPasswordLoading,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) {
                            if (!authProvider.resetPasswordLoading) {
                              _submitReset();
                            }
                          },
                          decoration: _decoration(
                            hint: 'Confirm New Password',
                            prefix: Icons.lock_outline,
                            suffix: IconButton(
                              tooltip: _obscureConfirmPassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password.';
                            }

                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match.';
                            }

                            return null;
                          },
                        ),

                        if (authProvider.passwordResetError != null) ...[
                          const SizedBox(height: 16),
                          _MessageBox(
                            text: authProvider.passwordResetError!,
                            error: true,
                          ),
                        ],

                        const SizedBox(height: 24),

                        SizedBox(
                          height: 53,
                          child: FilledButton(
                            onPressed: authProvider.resetPasswordLoading
                                ? null
                                : _submitReset,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            child: authProvider.resetPasswordLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Reset Password',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed:
                              authProvider.forgotPasswordLoading ||
                                  authProvider.resetPasswordLoading
                              ? null
                              : _resendCode,
                          child: authProvider.forgotPasswordLoading
                              ? const Text('Sending code...')
                              : const Text('Resend Code'),
                        ),

                        const SizedBox(height: 4),

                        TextButton.icon(
                          onPressed: authProvider.resetPasswordLoading
                              ? null
                              : () {
                                  Navigator.of(context).pop(false);
                                },
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Back to Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RESET ICON
// ============================================================

class _ResetIcon extends StatelessWidget {
  const _ResetIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 68,
        height: 68,
        decoration: const BoxDecoration(
          color: AppColors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_reset_rounded,
          size: 33,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

// ============================================================
// MESSAGE BOX
// ============================================================

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.text, required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.error : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(color: color),
      ),
    );
  }
}

// ============================================================
// INPUT DECORATION
// ============================================================

InputDecoration _decoration({
  required String hint,
  required IconData prefix,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(prefix),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.background,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
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
