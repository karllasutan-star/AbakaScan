import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../providers/app_providers.dart';

import 'about_screen.dart';
import 'classify_screen.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'samples_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

  Future<void> _openSamples(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SamplesScreen()));
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
    final authProvider = context.watch<AuthProvider>();

    final user = authProvider.currentUser;

    final fullName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : 'ABAKASCAN User';

    final email = user?.email.trim().isNotEmpty == true
        ? user!.email.trim()
        : 'No email available';

    final accountRole = authProvider.isAdmin ? 'Administrator' : 'User';

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
                  child: _ProfileSidebar(
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
                  child: _ProfileBody(
                    fullName: fullName,
                    email: email,
                    accountRole: accountRole,
                    onSettings: () {
                      _openSettings(context);
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
            title: const Text('Profile', style: AppTypography.cardTitle),
            actions: [
              IconButton(
                tooltip: 'Settings',
                onPressed: () {
                  _openSettings(context);
                },
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: _ProfileBody(
            fullName: fullName,
            email: email,
            accountRole: accountRole,
            onSettings: () {
              _openSettings(context);
            },
            onLogout: () {
              _logout(context);
            },
            compact: true,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 3,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                label: 'Reports',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  _returnDashboard(context);
                  break;

                case 1:
                  _openHistory(context);
                  break;

                case 2:
                  _openReports(context);
                  break;

                case 3:
                  break;
              }
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

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.fullName,
    required this.email,
    required this.accountRole,
    required this.onSettings,
    required this.onLogout,
    this.compact = false,
  });

  final String fullName;
  final String email;
  final String accountRole;

  final VoidCallback onSettings;
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
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) const _DesktopHeader(),

              if (!compact) const SizedBox(height: 22),

              _ProfileHero(
                fullName: fullName,
                email: email,
                accountRole: accountRole,
                compact: compact,
              ),

              const SizedBox(height: 18),

              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 760;

                  final account = _AccountInformation(
                    fullName: fullName,
                    email: email,
                    accountRole: accountRole,
                  );

                  final access = _AccountAccessCard(accountRole: accountRole);

                  if (stacked) {
                    return Column(
                      children: [account, const SizedBox(height: 14), access],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: account),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: access),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),

              _ProfileActions(
                compact: compact,
                onSettings: onSettings,
                onLogout: onLogout,
              ),
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
          'ACCOUNT',
          style: AppTypography.label.copyWith(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Your Profile',
          style: AppTypography.pageTitle.copyWith(fontSize: 34),
        ),

        const SizedBox(height: 7),

        Text(
          'View the account currently signed in to ABAKASCAN.',
          style: AppTypography.bodySecondary.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

// ============================================================
// PROFILE HERO
// ============================================================

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.fullName,
    required this.email,
    required this.accountRole,
    required this.compact,
  });

  final String fullName;
  final String email;
  final String accountRole;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 225 : 250,
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
                    Color(0xF40F3D2E),
                    Color(0xD20F3D2E),
                    Color(0x650F3D2E),
                    Color(0x200F3D2E),
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
              child: Row(
                children: [
                  _ProfileAvatar(name: fullName, compact: compact),

                  SizedBox(width: compact ? 15 : 20),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.pageTitle.copyWith(
                            color: Colors.white,
                            fontSize: compact ? 24 : 30,
                            height: 1.05,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySecondary.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),

                        const SizedBox(height: 13),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.fiberBeige.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.fiberBeige.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: Text(
                            accountRole.toUpperCase(),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.fiberBeige,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name, required this.compact});

  final String name;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 76.0 : 92.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.fiberBeige, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: AppTypography.sectionTitle.copyWith(
          color: AppColors.primaryDark,
          fontSize: compact ? 23 : 28,
        ),
      ),
    );
  }
}

// ============================================================
// ACCOUNT INFORMATION
// ============================================================

class _AccountInformation extends StatelessWidget {
  const _AccountInformation({
    required this.fullName,
    required this.email,
    required this.accountRole,
  });

  final String fullName;
  final String email;
  final String accountRole;

  @override
  Widget build(BuildContext context) {
    return _ProfilePanel(
      title: 'Account Information',
      subtitle:
          'Information returned for your authenticated ABAKASCAN account.',
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.person_outline_rounded,
            label: 'Full Name',
            value: fullName,
          ),

          const Divider(height: 25),

          _InformationRow(
            icon: Icons.email_outlined,
            label: 'Email Address',
            value: email,
          ),

          const Divider(height: 25),

          _InformationRow(
            icon: Icons.badge_outlined,
            label: 'Account Role',
            value: accountRole,
          ),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption),

              const SizedBox(height: 4),

              SelectableText(
                value,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ACCESS CARD
// ============================================================

class _AccountAccessCard extends StatelessWidget {
  const _AccountAccessCard({required this.accountRole});

  final String accountRole;

  @override
  Widget build(BuildContext context) {
    return _ProfilePanel(
      title: 'Account Access',
      subtitle: 'Current authorization information.',
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              accountRole == 'Administrator'
                  ? Icons.admin_panel_settings_outlined
                  : Icons.verified_user_outlined,
              color: AppColors.primaryDark,
              size: 31,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            accountRole,
            textAlign: TextAlign.center,
            style: AppTypography.sectionTitle.copyWith(
              color: AppColors.primaryDark,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            accountRole == 'Administrator'
                ? 'This account has administrator authorization.'
                : 'This account is signed in as a standard ABAKASCAN user.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary.copyWith(height: 1.5),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: AppColors.primary,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Account information is managed through the authenticated system session.',
                    style: AppTypography.caption.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTIONS
// ============================================================

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({
    required this.compact,
    required this.onSettings,
    required this.onLogout,
  });

  final bool compact;

  final VoidCallback onSettings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final settingsButton = SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onSettings,
        icon: const Icon(Icons.settings_outlined),
        label: const Text('Open Settings'),
      ),
    );

    final logoutButton = SizedBox(
      height: 50,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
        onPressed: onLogout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Log Out'),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [settingsButton, const SizedBox(height: 10), logoutButton],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [settingsButton, const SizedBox(width: 10), logoutButton],
      ),
    );
  }
}

// ============================================================
// PANEL
// ============================================================

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 15)),

          const SizedBox(height: 4),

          Text(subtitle, style: AppTypography.caption.copyWith(height: 1.45)),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }
}

// ============================================================
// DESKTOP SIDEBAR
// ============================================================

class _ProfileSidebar extends StatelessWidget {
  const _ProfileSidebar({
    required this.onDashboard,
    required this.onClassify,
    required this.onHistory,
    required this.onSamples,
    required this.onReports,
    required this.onSettings,
    required this.onAbout,
    required this.onLogout,
  });

  final VoidCallback onDashboard;
  final VoidCallback onClassify;
  final VoidCallback onHistory;
  final VoidCallback onSamples;
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
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            selected: true,
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
              width: double.infinity,
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/abakascan_auth_hero.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: AppColors.primaryDark.withValues(alpha: 0.48),
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
// DECORATION
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

// ============================================================
// HELPERS
// ============================================================

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return 'U';
  }

  if (parts.length == 1) {
    return parts.first[0].toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
