import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_navigation.dart';
import '../app/theme.dart';
import '../providers/app_providers.dart';

import 'about_screen.dart';
import 'classify_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'samples_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _returnDashboard(BuildContext context) {
    returnToDashboard(context);
  }

  Future<void> _openClassify(BuildContext context) async {
    await openSection(context, const ClassifyScreen());
  }

  Future<void> _openHistory(BuildContext context) async {
    await openSection(context, const HistoryScreen());
  }

  Future<void> _openSamples(BuildContext context) async {
    await openSection(context, const SamplesScreen());
  }

  Future<void> _openReports(BuildContext context) async {
    await openSection(context, const ReportsScreen());
  }

  Future<void> _openProfile(BuildContext context) async {
    await openSection(context, const ProfileScreen());
  }

  Future<void> _openAbout(BuildContext context) async {
    await openSection(context, const AboutScreen());
  }

  Future<void> _openAppearance(BuildContext context) async {
    final appearanceProvider = context.read<AppearanceProvider>();

    final selected = await showModalBottomSheet<AppAppearance>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final currentAppearance = appearanceProvider.appearance;
        final colors = Theme.of(sheetContext).colorScheme;

        Widget option({
          required AppAppearance appearance,
          required IconData icon,
          required String description,
        }) {
          final selected = currentAppearance == appearance;

          return ListTile(
            leading: Icon(
              icon,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
            title: Text(
              appearance.displayName,
              style: AppTypography.body.copyWith(
                color: colors.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              description,
              style: AppTypography.caption.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
            selected: selected,
            selectedTileColor: colors.primaryContainer.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              Navigator.pop(sheetContext, appearance);
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    'Appearance',
                    style: AppTypography.cardTitle.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Choose how ABAKASCAN should appear.',
                    style: AppTypography.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                option(
                  appearance: AppAppearance.system,
                  icon: Icons.settings_brightness_rounded,
                  description: 'Follow your device theme.',
                ),
                option(
                  appearance: AppAppearance.light,
                  icon: Icons.light_mode_outlined,
                  description: 'Always use the light theme.',
                ),
                option(
                  appearance: AppAppearance.dark,
                  icon: Icons.dark_mode_outlined,
                  description: 'Always use the dark theme.',
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !context.mounted) {
      return;
    }

    appearanceProvider.setAppearance(selected);
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          icon: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.logout_rounded, color: colors.primary),
          ),
          title: const Text('Log Out?'),
          content: const Text(
            'You will need to sign in again to access your ABAKASCAN account.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

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
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= AppBreakpoints.desktop;

        if (desktop) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Row(
              children: [
                SizedBox(
                  width: 214,
                  child: _SettingsSidebar(
                    onDashboard: () {
                      _returnDashboard(context);
                    },
                    onClassify: () {
                      _openClassify(context);
                    },
                    onHistory: () {
                      _openHistory(context);
                    },
                    onSamples: () {
                      _openSamples(context);
                    },
                    onReports: () {
                      _openReports(context);
                    },
                    onProfile: () {
                      _openProfile(context);
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
                  child: _SettingsBody(
                    onAppearance: () {
                      _openAppearance(context);
                    },
                    onProfile: () {
                      _openProfile(context);
                    },
                    onAbout: () {
                      _openAbout(context);
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            surfaceTintColor: Colors.transparent,
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
            title: Text(
              'Settings',
              style: AppTypography.cardTitle.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          body: _SettingsBody(
            compact: true,
            onAppearance: () {
              _openAppearance(context);
            },
            onProfile: () {
              _openProfile(context);
            },
            onAbout: () {
              _openAbout(context);
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

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.onAppearance,
    required this.onProfile,
    required this.onAbout,
    this.compact = false,
  });

  final VoidCallback onAppearance;
  final VoidCallback onProfile;
  final VoidCallback onAbout;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final appearanceProvider = context.watch<AppearanceProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 28,
        compact ? 8 : 26,
        compact ? 16 : 28,
        40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) const _DesktopHeader(),

              if (!compact) const SizedBox(height: 22),

              const _SettingsHero(),

              const SizedBox(height: 18),

              _SettingsSection(
                title: 'Application',
                subtitle: 'Personalize how ABAKASCAN works for you.',
                children: [
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    description: 'Theme and visual preferences.',
                    status: appearanceProvider.appearance.displayName,
                    onTap: onAppearance,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SettingsSection(
                title: 'Account',
                subtitle: 'Manage your ABAKASCAN account information.',
                children: [
                  _SettingsItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile',
                    description: 'View your account information.',
                    onTap: onProfile,
                  ),
                  _SettingsItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About ABAKASCAN',
                    description: 'View system information and project details.',
                    onTap: onAbout,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREFERENCES',
          style: AppTypography.label.copyWith(
            color: colors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Settings',
          style: AppTypography.pageTitle.copyWith(
            fontSize: 34,
            color: colors.onSurface,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          'Manage available application and account options.',
          style: AppTypography.bodySecondary.copyWith(
            height: 1.5,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _SettingsHero extends StatelessWidget {
  const _SettingsHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 190,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/abakascan_auth_hero.png',
              fit: BoxFit.cover,
            ),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF50F3D2E),
                    Color(0xCE0F3D2E),
                    Color(0x490F3D2E),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Brand(),

                  const Spacer(),

                  Text(
                    'Your workspace,\nyour preferences.',
                    style: AppTypography.pageTitle.copyWith(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.04,
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
// SETTINGS SECTION
// ============================================================

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 17, 17, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(
                    fontSize: 15,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          for (var index = 0; index < children.length; index++) ...[
            children[index],

            if (index < children.length - 1)
              const Divider(height: 1, indent: 70),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// SETTING ITEM
// ============================================================

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.status,
  });

  final IconData icon;

  final String title;
  final String description;

  final String? status;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: colors.primary),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 13,
                        color: colors.onSurface,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      description,
                      style: AppTypography.caption.copyWith(
                        height: 1.4,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              if (status != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status!,
                    style: AppTypography.caption.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 7),
              ],

              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SIDEBAR
// ============================================================

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar({
    required this.onDashboard,
    required this.onClassify,
    required this.onHistory,
    required this.onSamples,
    required this.onReports,
    required this.onProfile,
    required this.onAbout,
    required this.onLogout,
  });

  final VoidCallback onDashboard;
  final VoidCallback onClassify;
  final VoidCallback onHistory;
  final VoidCallback onSamples;
  final VoidCallback onReports;
  final VoidCallback onProfile;
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

          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            label: 'Samples',
            onTap: onSamples,
          ),

          _SidebarItem(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            onTap: onReports,
          ),

          const _SidebarItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            selected: true,
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
// DECORATIVE LINES
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
