import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../providers/app_providers.dart';

import 'about_screen.dart';
import 'classify_screen.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class SamplesScreen extends StatelessWidget {
  const SamplesScreen({super.key});

  void _returnDashboard(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openClassify(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ClassifyScreen()));
  }

  Future<void> _openHistory(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  Future<void> _openReports(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _openAbout(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AboutScreen()));
  }

  Future<void> _logout(BuildContext context) async {
    context.read<ImageSelectionProvider>().removeImage();

    context.read<ClassificationProvider>().reset();

    context.read<HistoryProvider>().reset();

    context.read<AdminProvider>().reset();

    await context.read<AuthProvider>().logout();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= AppBreakpoints.desktop;

        if (desktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                SizedBox(
                  width: 214,
                  child: _SamplesSidebar(
                    onDashboard: () {
                      _returnDashboard(context);
                    },
                    onClassify: () {
                      _openClassify(context);
                    },
                    onHistory: () {
                      _openHistory(context);
                    },
                    onReports: () {
                      _openReports(context);
                    },
                    onSettings: () {
                      _openSettings(context);
                    },
                    onAbout: () {
                      _openAbout(context);
                    },
                    onLogout: () {
                      _logout(context);
                    },
                  ),
                ),

                Expanded(
                  child: _SamplesBody(
                    onAnalyze: () {
                      _openClassify(context);
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              tooltip: 'Back',
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.pop(context);
                } else {
                  _returnDashboard(context);
                }
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text('Samples', style: AppTypography.cardTitle),
          ),
          body: _SamplesBody(
            compact: true,
            onAnalyze: () {
              _openClassify(context);
            },
          ),
        );
      },
    );
  }
}

// ============================================================
// BODY
// ============================================================

class _SamplesBody extends StatelessWidget {
  const _SamplesBody({required this.onAnalyze, this.compact = false});

  final VoidCallback onAnalyze;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 28,
        compact ? 8 : 26,
        compact ? 16 : 28,
        40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) const _DesktopHeader(),

              if (!compact) const SizedBox(height: 22),

              _SamplesHero(compact: compact),

              const SizedBox(height: 18),

              _LibraryStatus(compact: compact, onAnalyze: onAnalyze),

              const SizedBox(height: 18),

              const _ReferenceRequirements(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DESKTOP HEADER
// ============================================================

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REFERENCE LIBRARY',
          style: AppTypography.label.copyWith(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Fiber Samples',
          style: AppTypography.pageTitle.copyWith(fontSize: 34),
        ),

        const SizedBox(height: 7),

        Text(
          'A future workspace for verified abaca fiber reference samples.',
          style: AppTypography.bodySecondary.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _SamplesHero extends StatelessWidget {
  const _SamplesHero({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 220 : 250,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/abakascan_auth_hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF20F3D2E),
                    Color(0xC80F3D2E),
                    Color(0x6A0F3D2E),
                    Color(0x240F3D2E),
                  ],
                ),
              ),
            ),

            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _FiberLinePainter()),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(compact ? 20 : 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Brand(),

                  const Spacer(),

                  Text(
                    'Reference fibers,\nwhen verified.',
                    style: AppTypography.pageTitle.copyWith(
                      color: Colors.white,
                      fontSize: compact ? 28 : 32,
                      height: 1.04,
                    ),
                  ),

                  const SizedBox(height: 9),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Text(
                      'This library is reserved for approved reference images and confirmed grade information.',
                      style: AppTypography.bodySecondary.copyWith(
                        color: Colors.white.withValues(alpha: 0.76),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LIBRARY STATUS
// ============================================================

class _LibraryStatus extends StatelessWidget {
  const _LibraryStatus({required this.compact, required this.onAnalyze});

  final bool compact;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 720;

          final icon = Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.collections_bookmark_outlined,
              size: 34,
              color: AppColors.primaryDark,
            ),
          );

          final information = Expanded(
            child: Column(
              crossAxisAlignment: stacked
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  'No approved reference library available',
                  textAlign: stacked ? TextAlign.center : TextAlign.left,
                  style: AppTypography.sectionTitle.copyWith(fontSize: 21),
                ),

                const SizedBox(height: 8),

                Text(
                  'ABAKASCAN currently has no approved reference-sample dataset available for display. '
                  'Reference images and grade examples will only be shown when a verified source is available.',
                  textAlign: stacked ? TextAlign.center : TextAlign.left,
                  style: AppTypography.bodySecondary.copyWith(height: 1.55),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                    ),
                    onPressed: onAnalyze,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Analyze Your Own Fiber'),
                  ),
                ),
              ],
            ),
          );

          if (stacked) {
            return Column(
              children: [icon, const SizedBox(height: 18), information],
            );
          }

          return Row(children: [icon, const SizedBox(width: 24), information]);
        },
      ),
    );
  }
}

// ============================================================
// REFERENCE REQUIREMENTS
// ============================================================

class _ReferenceRequirements extends StatelessWidget {
  const _ReferenceRequirements();

  @override
  Widget build(BuildContext context) {
    const items = [
      _ReferenceRequirementData(
        icon: Icons.image_outlined,
        title: 'Approved Fiber Image',
        description: 'A reference sample should come from a verified and permitted image source.',
      ),
      _ReferenceRequirementData(
        icon: Icons.fact_check_outlined,
        title: 'Confirmed Grade',
        description: 'The grade shown beside a reference image should come from a trusted source rather than a generated label.',
      ),
      _ReferenceRequirementData(
        icon: Icons.source_outlined,
        title: 'Source Information',
        description: 'Reference entries should preserve enough source information to explain where the sample came from.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'What a reference sample needs',
                style: AppTypography.sectionTitle.copyWith(fontSize: 18),
              ),
            ),

            Text(
              'REFERENCE STANDARD',
              style: AppTypography.label.copyWith(
                color: AppColors.primary,
                fontSize: 9,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),

        const SizedBox(height: 13),

        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    _ReferenceCard(data: items[index]),
                    if (index < items.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  Expanded(child: _ReferenceCard(data: items[index])),
                  if (index < items.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReferenceRequirementData {
  const _ReferenceRequirementData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.data});

  final _ReferenceRequirementData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: AppColors.primary, size: 20),
          ),

          const SizedBox(height: 13),

          Text(
            data.title,
            style: AppTypography.cardTitle.copyWith(fontSize: 14),
          ),

          const SizedBox(height: 5),

          Text(
            data.description,
            style: AppTypography.caption.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SIDEBAR
// ============================================================

class _SamplesSidebar extends StatelessWidget {
  const _SamplesSidebar({
    required this.onDashboard,
    required this.onClassify,
    required this.onHistory,
    required this.onReports,
    required this.onSettings,
    required this.onAbout,
    required this.onLogout,
  });

  final VoidCallback onDashboard;
  final VoidCallback onClassify;
  final VoidCallback onHistory;
  final VoidCallback onReports;
  final VoidCallback onSettings;
  final VoidCallback onAbout;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(14, 26, 14, 18),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: _Brand(),
          ),

          const SizedBox(height: 34),

          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            onTap: onDashboard,
          ),

          _SidebarItem(
            icon: Icons.camera_alt_outlined,
            label: 'Analyze',
            onTap: onClassify,
          ),

          _SidebarItem(
            icon: Icons.history_rounded,
            label: 'History',
            onTap: onHistory,
          ),

          const _SidebarItem(
            icon: Icons.inventory_2_outlined,
            label: 'Samples',
            selected: true,
          ),

          _SidebarItem(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            onTap: onReports,
          ),

          _SidebarItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: onSettings,
          ),

          const Spacer(),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/abakascan_auth_hero.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: AppColors.primaryDark.withValues(alpha: 0.50),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          _SidebarItem(
            icon: Icons.info_outline_rounded,
            label: 'About',
            onTap: onAbout,
          ),

          _SidebarItem(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;

  final bool selected;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.74);

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 19, color: foreground),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodySecondary.copyWith(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        const Icon(Icons.eco_outlined, color: AppColors.fiberBeige, size: 24),

        const SizedBox(width: 9),

        Text(
          'ABAKASCAN',
          style: AppTypography.label.copyWith(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FIBER LINES
// ============================================================

class _FiberLinePainter extends CustomPainter {
  const _FiberLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < 10; index++) {
      final y = size.height * (0.35 + index * 0.026);

      final path = Path()
        ..moveTo(-20, y)
        ..cubicTo(
          size.width * 0.28,
          y + 38,
          size.width * 0.66,
          y - 34,
          size.width + 25,
          y + 8,
        );

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = index % 3 == 0 ? 1.1 : 0.7
          ..color = AppColors.fiberBeige.withValues(alpha: 0.30),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
