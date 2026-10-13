import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  Future<void> _openSamples(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SamplesScreen()));
  }

  Future<void> _openReports(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  Future<void> _openAbout(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AboutScreen()));
  }

  void _showUnavailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature is not connected yet.')));
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.primaryDark,
            ),
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
                backgroundColor: AppColors.primaryDark,
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
                      _showUnavailable(context, 'Appearance');
                    },
                    onNotifications: () {
                      _showUnavailable(context, 'Notifications');
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
            title: const Text('Settings', style: AppTypography.cardTitle),
          ),
          body: _SettingsBody(
            compact: true,
            onAppearance: () {
              _showUnavailable(context, 'Appearance');
            },
            onNotifications: () {
              _showUnavailable(context, 'Notifications');
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
    required this.onNotifications,
    required this.onProfile,
    required this.onAbout,
    required this.onLogout,
    this.compact = false,
  });

  final VoidCallback onAppearance;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback onAbout;
  final VoidCallback onLogout;

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
                    status: 'Not connected yet',
                    unavailable: true,
                    onTap: onAppearance,
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    description: 'Notification and alert preferences.',
                    status: 'Not connected yet',
                    unavailable: true,
                    onTap: onNotifications,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SettingsSection(
                title: 'Account',
                subtitle: 'Manage your ABAKASCAN account access.',
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

              const SizedBox(height: 16),

              _SessionSection(onLogout: onLogout),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREFERENCES',
          style: AppTypography.label.copyWith(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text('Settings', style: AppTypography.pageTitle.copyWith(fontSize: 34)),
        const SizedBox(height: 7),
        Text(
          'Manage available application and account options.',
          style: AppTypography.bodySecondary.copyWith(height: 1.5),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
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
                  style: AppTypography.cardTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTypography.caption),
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
    this.unavailable = false,
  });

  final IconData icon;

  final String title;
  final String description;

  final String? status;

  final bool unavailable;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                  color: unavailable
                      ? AppColors.surfaceMuted
                      : AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: unavailable
                      ? AppColors.textSecondary
                      : AppColors.primary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.cardTitle.copyWith(fontSize: 13),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      description,
                      style: AppTypography.caption.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              if (status != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status!,
                    style: AppTypography.caption.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(width: 7),

              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SESSION
// ============================================================

class _SessionSection extends StatelessWidget {
  const _SessionSection({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 600;

          final text = const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account Session', style: AppTypography.cardTitle),
              SizedBox(height: 4),
              Text(
                'Sign out of the currently authenticated ABAKASCAN account.',
                style: AppTypography.caption,
              ),
            ],
          );

          final button = SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.45),
                ),
              ),
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log Out'),
            ),
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: 16), button],
            );
          }

          return Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account Session', style: AppTypography.cardTitle),
                    SizedBox(height: 4),
                    Text(
                      'Sign out of the currently authenticated ABAKASCAN account.',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              button,
            ],
          );
        },
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

          _SidebarItem(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: onProfile,
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
