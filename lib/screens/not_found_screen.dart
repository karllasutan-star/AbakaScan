import 'package:flutter/material.dart';

import '../app/theme.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.routeName});

  final String? routeName;

  void _returnHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final requestedRoute = routeName?.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                children: [
                  _BrandHeader(),

                  const SizedBox(height: AppSpacing.xxxl),

                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_off_outlined,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    '404',
                    style: AppTypography.pageTitle.copyWith(
                      color: AppColors.primary,
                      fontSize: 52,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  const Text(
                    'Page Not Found',
                    textAlign: TextAlign.center,
                    style: AppTypography.pageTitle,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: const Text(
                      'The page you are trying to open does not exist, '
                      'may have been moved, or is not available from this route.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySecondary,
                    ),
                  ),

                  if (requestedRoute != null && requestedRoute.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.mediumRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Requested Route',
                            style: AppTypography.caption,
                          ),

                          const SizedBox(height: AppSpacing.xs),

                          SelectableText(
                            requestedRoute,
                            style: AppTypography.body,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  FilledButton.icon(
                    onPressed: () {
                      _returnHome(context);
                    },
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Return Home'),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),

                  const _SystemNotice(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.eco_outlined, color: AppColors.primary, size: 26),

        const SizedBox(width: AppSpacing.sm),

        Text(
          'ABAKASCAN',
          style: AppTypography.label.copyWith(
            color: AppColors.primaryDark,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.6,
          ),
        ),
      ],
    );
  }
}

class _SystemNotice extends StatelessWidget {
  const _SystemNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 21),

          SizedBox(width: AppSpacing.md),

          Expanded(
            child: Text(
              'Use the ABAKASCAN navigation instead of manually entering an unknown page address.',
              style: AppTypography.bodySecondary,
            ),
          ),
        ],
      ),
    );
  }
}
