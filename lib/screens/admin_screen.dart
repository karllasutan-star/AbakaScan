import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/admin_models.dart';
import '../providers/app_providers.dart';

enum _AdminSection { overview, accounts, classifications }

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  _AdminSection _selectedSection = _AdminSection.overview;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdminData();
    });
  }

  Future<void> _loadAdminData() async {
    final token = context.read<AuthProvider>().token;

    if (token == null || token.trim().isEmpty) {
      return;
    }

    final adminProvider = context.read<AdminProvider>();

    await adminProvider.loadAll(token: token);

    if (!mounted) {
      return;
    }

    if (adminProvider.sessionExpired) {
      await _handleExpiredSession();
    }
  }

  Future<void> _refreshCurrentSection() async {
    final token = context.read<AuthProvider>().token;

    if (token == null || token.trim().isEmpty) {
      return;
    }

    final adminProvider = context.read<AdminProvider>();

    switch (_selectedSection) {
      case _AdminSection.overview:
        await adminProvider.loadOverview(token: token);
        await adminProvider.loadClassifications(token: token);
        break;

      case _AdminSection.accounts:
        await adminProvider.loadUsers(token: token);
        break;

      case _AdminSection.classifications:
        await adminProvider.loadClassifications(token: token);
        break;
    }

    if (!mounted) {
      return;
    }

    if (adminProvider.sessionExpired) {
      await _handleExpiredSession();
    }
  }

  Future<void> _refreshAll() async {
    final token = context.read<AuthProvider>().token;

    if (token == null || token.trim().isEmpty) {
      return;
    }

    final adminProvider = context.read<AdminProvider>();

    await adminProvider.refreshAll(token: token);

    if (!mounted) {
      return;
    }

    if (adminProvider.sessionExpired) {
      await _handleExpiredSession();
    }
  }

  Future<void> _handleExpiredSession() async {
    context.read<AdminProvider>().reset();

    context.read<HistoryProvider>().reset();

    context.read<ClassificationProvider>().reset();

    context.read<ImageSelectionProvider>().removeImage();

    await context.read<AuthProvider>().expireSession();

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _logout() async {
    context.read<AdminProvider>().reset();

    context.read<HistoryProvider>().reset();

    context.read<ClassificationProvider>().reset();

    context.read<ImageSelectionProvider>().removeImage();

    await context.read<AuthProvider>().logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _selectSection(_AdminSection section) {
    if (_selectedSection == section) {
      return;
    }

    setState(() {
      _selectedSection = section;
    });
  }

  Future<void> _openCreateAdmin() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CreateAdminDialog(),
    );

    if (!mounted) {
      return;
    }

    final adminProvider = context.read<AdminProvider>();

    if (adminProvider.sessionExpired) {
      await _handleExpiredSession();
      return;
    }

    if (created != true) {
      return;
    }

    final token = context.read<AuthProvider>().token;

    if (token != null && token.trim().isNotEmpty) {
      await Future.wait([
        adminProvider.loadOverview(token: token),
        adminProvider.loadUsers(token: token),
      ]);
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Administrator account created successfully.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final rawName = authProvider.currentUser?.fullName;

    final adminName = rawName != null && rawName.trim().isNotEmpty
        ? rawName.trim()
        : 'Administrator';

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
                  child: _AdminSidebar(
                    selectedSection: _selectedSection,
                    onSectionSelected: _selectSection,
                    onLogout: _logout,
                  ),
                ),
                Expanded(
                  child: _AdminBody(
                    adminName: adminName,
                    selectedSection: _selectedSection,
                    onRefreshCurrent: _refreshCurrentSection,
                    onRefreshAll: _refreshAll,
                    onCreateAdmin: _openCreateAdmin,
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
            title: const _Brand(darkText: true),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refreshCurrentSection,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          drawer: _AdminDrawer(
            selectedSection: _selectedSection,
            onSectionSelected: _selectSection,
            onLogout: _logout,
          ),
          body: _AdminBody(
            adminName: adminName,
            selectedSection: _selectedSection,
            onRefreshCurrent: _refreshCurrentSection,
            onRefreshAll: _refreshAll,
            onCreateAdmin: _openCreateAdmin,
            compact: true,
          ),
        );
      },
    );
  }
}

// ============================================================
// BODY
// ============================================================

class _AdminBody extends StatelessWidget {
  const _AdminBody({
    required this.adminName,
    required this.selectedSection,
    required this.onRefreshCurrent,
    required this.onRefreshAll,
    required this.onCreateAdmin,
    this.compact = false,
  });

  final String adminName;

  final _AdminSection selectedSection;

  final Future<void> Function() onRefreshCurrent;

  final Future<void> Function() onRefreshAll;

  final Future<void> Function() onCreateAdmin;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefreshCurrent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 28,
          compact ? 14 : 26,
          compact ? 16 : 28,
          40,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminHeader(
                  adminName: adminName,
                  selectedSection: selectedSection,
                  onRefresh: onRefreshCurrent,
                  compact: compact,
                ),

                const SizedBox(height: 20),

                switch (selectedSection) {
                  _AdminSection.overview => _OverviewSection(
                    onRefresh: onRefreshAll,
                    onCreateAdmin: onCreateAdmin,
                  ),

                  _AdminSection.accounts => _AccountsSection(
                    onRefresh: onRefreshCurrent,
                    onCreateAdmin: onCreateAdmin,
                  ),

                  _AdminSection.classifications => _ClassificationsSection(
                    onRefresh: onRefreshCurrent,
                  ),
                },

                const SizedBox(height: 20),

                const _AdminAccessNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.adminName,
    required this.selectedSection,
    required this.onRefresh,
    required this.compact,
  });

  final String adminName;
  final _AdminSection selectedSection;

  final Future<void> Function() onRefresh;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final title = switch (selectedSection) {
      _AdminSection.overview => 'Administrator Dashboard',
      _AdminSection.accounts => 'Account Management',
      _AdminSection.classifications => 'Classification Records',
    };

    final description = switch (selectedSection) {
      _AdminSection.overview =>
        'Monitor account and classification activity across ABAKASCAN.',
      _AdminSection.accounts => 'Review registered accounts and create authorized administrator accounts.',
      _AdminSection.classifications =>
        'Review classification records created across user accounts.',
    };

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADMINISTRATION',
          style: AppTypography.label.copyWith(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppTypography.pageTitle.copyWith(fontSize: compact ? 27 : 34),
        ),
        const SizedBox(height: 7),
        Text(
          'Signed in as $adminName',
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            description,
            style: AppTypography.bodySecondary.copyWith(height: 1.5),
          ),
        ),
      ],
    );

    if (compact) {
      return heading;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: heading),
        const SizedBox(width: 20),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
      ],
    );
  }
}

// ============================================================
// OVERVIEW
// ============================================================

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.onRefresh,
    required this.onCreateAdmin,
  });

  final Future<void> Function() onRefresh;

  final Future<void> Function() onCreateAdmin;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    if (admin.overviewLoading && admin.overview == null) {
      return const _AdminLoadingState(
        message: 'Loading administrator dashboard...',
      );
    }

    if (admin.overviewError != null && admin.overview == null) {
      return _AdminErrorState(
        title: 'Unable to load administrator dashboard',
        message: admin.overviewError!,
        onRetry: onRefresh,
      );
    }

    final overview = admin.overview;

    if (overview == null) {
      return _AdminErrorState(
        title: 'Dashboard unavailable',
        message: 'Administrator statistics are not available yet.',
        onRetry: onRefresh,
      );
    }

    final latest = admin.latestClassification;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminHero(
          totalAccounts: overview.totalUsers,
          totalClassifications: overview.totalClassifications,
          onCreateAdmin: onCreateAdmin,
        ),

        const SizedBox(height: 18),

        _OverviewCards(
          totalUsers: overview.totalUsers,
          regularUsers: overview.totalRegularUsers,
          admins: overview.totalAdmins,
          classifications: overview.totalClassifications,
        ),

        const SizedBox(height: 18),

        _SectionCard(
          title: 'Latest Classification',
          subtitle: 'Most recent system-wide classification activity.',
          trailing: admin.classificationsLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          child: latest == null
              ? const _MiniEmptyState(
                  icon: Icons.analytics_outlined,
                  title: 'No classification records yet',
                  description: 'Classification activity will appear here when users begin analyzing images.',
                )
              : _LatestClassification(record: latest),
        ),
      ],
    );
  }
}

class _AdminHero extends StatelessWidget {
  const _AdminHero({
    required this.totalAccounts,
    required this.totalClassifications,
    required this.onCreateAdmin,
  });

  final int totalAccounts;
  final int totalClassifications;

  final Future<void> Function() onCreateAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 230,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
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
                  Color(0xF60F3D2E),
                  Color(0xDC0F3D2E),
                  Color(0x700F3D2E),
                  Color(0x220F3D2E),
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
            padding: const EdgeInsets.all(22),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 660;

                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _Brand(),
                    const SizedBox(height: 26),
                    Text(
                      'System intelligence\nat a glance.',
                      style: AppTypography.pageTitle.copyWith(
                        color: Colors.white,
                        fontSize: narrow ? 26 : 31,
                        height: 1.04,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '$totalAccounts accounts • '
                      '$totalClassifications classifications',
                      style: AppTypography.bodySecondary.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                );

                final action = FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.fiberBeige,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  onPressed: onCreateAdmin,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Create Administrator'),
                );

                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: content),
                      SizedBox(width: double.infinity, child: action),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: content),
                    action,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({
    required this.totalUsers,
    required this.regularUsers,
    required this.admins,
    required this.classifications,
  });

  final int totalUsers;
  final int regularUsers;
  final int admins;
  final int classifications;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricData(
        icon: Icons.people_outline,
        label: 'Total Accounts',
        value: totalUsers.toString(),
      ),
      _MetricData(
        icon: Icons.person_outline,
        label: 'Regular Users',
        value: regularUsers.toString(),
      ),
      _MetricData(
        icon: Icons.admin_panel_settings_outlined,
        label: 'Administrators',
        value: admins.toString(),
      ),
      _MetricData(
        icon: Icons.analytics_outlined,
        label: 'Classifications',
        value: classifications.toString(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return GridView.builder(
            itemCount: cards.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 130,
            ),
            itemBuilder: (context, index) {
              return _MetricCard(data: cards[index]);
            },
          );
        }

        return Row(
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(child: _MetricCard(data: cards[index])),
              if (index < cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: AppColors.primary, size: 19),
          ),
          const Spacer(),
          Text(
            data.value,
            style: AppTypography.sectionTitle.copyWith(
              color: AppColors.primaryDark,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 3),
          Text(data.label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

// ============================================================
// ACCOUNTS
// ============================================================

class _AccountsSection extends StatelessWidget {
  const _AccountsSection({
    required this.onRefresh,
    required this.onCreateAdmin,
  });

  final Future<void> Function() onRefresh;

  final Future<void> Function() onCreateAdmin;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: 'Registered Accounts',
          description: 'Review ABAKASCAN user and administrator accounts.',
          button: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
            ),
            onPressed: onCreateAdmin,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Create Administrator'),
          ),
        ),

        const SizedBox(height: 16),

        if (admin.usersLoading && admin.users.isEmpty)
          const _AdminLoadingState(message: 'Loading accounts...')
        else if (admin.usersError != null && admin.users.isEmpty)
          _AdminErrorState(
            title: 'Unable to load accounts',
            message: admin.usersError!,
            onRetry: onRefresh,
          )
        else if (admin.users.isEmpty)
          const _AdminEmptyState(
            icon: Icons.people_outline,
            title: 'No accounts available',
            description: 'Registered accounts will appear here.',
          )
        else ...[
          if (admin.usersError != null) ...[
            _AdminInlineError(
              message: admin.usersError!,
              onClose: () {
                context.read<AdminProvider>().clearUsersError();
              },
            ),
            const SizedBox(height: 12),
          ],
          _AccountsList(users: admin.users),
        ],
      ],
    );
  }
}

class _AccountsList extends StatelessWidget {
  const _AccountsList({required this.users});

  final List<AdminUserModel> users;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: [
              for (var index = 0; index < users.length; index++) ...[
                _AccountCard(user: users[index]),
                if (index < users.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(AppColors.surfaceMuted),
              columns: const [
                DataColumn(label: Text('NAME')),
                DataColumn(label: Text('EMAIL')),
                DataColumn(label: Text('ACCOUNT ROLE')),
                DataColumn(label: Text('STAKEHOLDER ROLE')),
                DataColumn(label: Text('CREATED')),
              ],
              rows: users.map((user) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(user.fullName.trim().isEmpty ? '—' : user.fullName),
                    ),
                    DataCell(
                      Text(user.email.trim().isEmpty ? '—' : user.email),
                    ),
                    DataCell(
                      _RoleBadge(
                        role: user.accountRoleLabel,
                        admin: user.isAdmin,
                      ),
                    ),
                    DataCell(Text(user.stakeholderDisplayName ?? '—')),
                    DataCell(
                      Text(
                        user.createdAt == null
                            ? '—'
                            : _formatDate(user.createdAt!),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final AdminUserModel user;

  @override
  Widget build(BuildContext context) {
    final displayName = user.fullName.trim().isEmpty
        ? 'Unnamed account'
        : user.fullName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  user.isAdmin
                      ? Icons.admin_panel_settings_outlined
                      : Icons.person_outline,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: AppTypography.cardTitle),
                    const SizedBox(height: 3),
                    Text(
                      user.email.trim().isEmpty
                          ? 'No email available'
                          : user.email,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              _RoleBadge(role: user.accountRoleLabel, admin: user.isAdmin),
            ],
          ),

          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),

          _AccountDetail(
            label: 'Stakeholder Role',
            value: user.stakeholderDisplayName ?? 'Not applicable',
          ),

          const SizedBox(height: 9),

          _AccountDetail(
            label: 'Created',
            value: user.createdAt == null
                ? '—'
                : _formatDateTime(user.createdAt!),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.admin});

  final String role;
  final bool admin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: admin ? AppColors.primarySoft : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: admin ? AppColors.primaryDark : AppColors.textSecondary,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AccountDetail extends StatelessWidget {
  const _AccountDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 125, child: Text(label, style: AppTypography.caption)),
        Expanded(child: Text(value, style: AppTypography.body)),
      ],
    );
  }
}

// ============================================================
// CLASSIFICATIONS
// ============================================================

class _ClassificationsSection extends StatelessWidget {
  const _ClassificationsSection({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'System Classifications',
          description:
              'Review classification records created by ABAKASCAN users.',
        ),

        const SizedBox(height: 16),

        if (admin.classificationsLoading && admin.classificationRecords.isEmpty)
          const _AdminLoadingState(message: 'Loading classification records...')
        else if (admin.classificationsError != null &&
            admin.classificationRecords.isEmpty)
          _AdminErrorState(
            title: 'Unable to load classifications',
            message: admin.classificationsError!,
            onRetry: onRefresh,
          )
        else if (admin.classificationRecords.isEmpty)
          const _AdminEmptyState(
            icon: Icons.analytics_outlined,
            title: 'No classification records yet',
            description: 'Classification records will appear here after users save analyses.',
          )
        else ...[
          if (admin.classificationsError != null) ...[
            _AdminInlineError(
              message: admin.classificationsError!,
              onClose: () {
                context.read<AdminProvider>().clearClassificationsError();
              },
            ),
            const SizedBox(height: 12),
          ],

          _ClassificationList(records: admin.classificationRecords),
        ],
      ],
    );
  }
}

class _ClassificationList extends StatelessWidget {
  const _ClassificationList({required this.records});

  final List<AdminClassificationRecordModel> records;

  @override
  Widget build(BuildContext context) {
    final sorted = [...records]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        for (var index = 0; index < sorted.length; index++) ...[
          _ClassificationCard(record: sorted[index]),
          if (index < sorted.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ClassificationCard extends StatelessWidget {
  const _ClassificationCard({required this.record});

  final AdminClassificationRecordModel record;

  @override
  Widget build(BuildContext context) {
    final confidence = _confidence(record.confidencePercentage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final information = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis ${_shortId(record.id)}',
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 14,
                      runSpacing: 7,
                      children: [
                        _MetaItem(
                          icon: Icons.person_outline,
                          text: record.ownerDisplayName,
                        ),
                        _MetaItem(
                          icon: Icons.calendar_today_outlined,
                          text: _formatDateTime(record.createdAt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final result = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GradeBadge(grade: record.predictedGrade),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${confidence.toStringAsFixed(1)}%',
                    style: AppTypography.cardTitle.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const Text('Confidence', style: AppTypography.caption),
                ],
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Details',
                onPressed: () {
                  _showClassificationDetails(context, record);
                },
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [
                information,
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [result],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: information),
              const SizedBox(width: 20),
              result,
            ],
          );
        },
      ),
    );
  }
}

class _LatestClassification extends StatelessWidget {
  const _LatestClassification({required this.record});

  final AdminClassificationRecordModel record;

  @override
  Widget build(BuildContext context) {
    final confidence = _confidence(record.confidencePercentage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;

          final identity = Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.document_scanner_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.predictedGrade,
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(record.ownerDisplayName, style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          );

          final details = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(
                '${confidence.toStringAsFixed(1)}% confidence',
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(record.createdAt),
                style: AppTypography.caption,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [identity, const SizedBox(height: 12), details],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              details,
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// GENERIC SECTION COMPONENTS
// ============================================================

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.description,
    this.button,
  });

  final String title;
  final String description;

  final Widget? button;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;

        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.sectionTitle.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 5),
            Text(description, style: AppTypography.bodySecondary),
          ],
        );

        if (button == null) {
          return heading;
        }

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [heading, const SizedBox(height: 14), button!],
          );
        }

        return Row(
          children: [
            Expanded(child: heading),
            const SizedBox(width: 20),
            button!,
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;

  final Widget child;
  final Widget? trailing;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
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
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.grade});

  final String grade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        grade,
        style: AppTypography.caption.copyWith(
          color: AppColors.primaryDark,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(text, style: AppTypography.caption),
      ],
    );
  }
}

// ============================================================
// STATES
// ============================================================

class _AdminLoadingState extends StatelessWidget {
  const _AdminLoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary,
          ),
        ],
      ),
    );
  }
}

class _AdminErrorState extends StatelessWidget {
  const _AdminErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 34, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _AdminInlineError extends StatelessWidget {
  const _AdminInlineError({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySecondary.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _AdminEmptyState extends StatelessWidget {
  const _AdminEmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 52),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 29, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: 7),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary,
          ),
        ],
      ),
    );
  }
}

class _MiniEmptyState extends StatelessWidget {
  const _MiniEmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle),
                const SizedBox(height: 3),
                Text(description, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminAccessNotice extends StatelessWidget {
  const _AdminAccessNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Administrator functions are protected by backend authorization. '
              'Only authorized administrator accounts should be able to access these operations.',
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DESKTOP SIDEBAR
// ============================================================

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.selectedSection,
    required this.onSectionSelected,
    required this.onLogout,
  });

  final _AdminSection selectedSection;

  final void Function(_AdminSection section) onSectionSelected;

  final Future<void> Function() onLogout;

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

          _SidebarLabel(text: 'ADMINISTRATION'),

          _AdminNavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            selected: selectedSection == _AdminSection.overview,
            onTap: () {
              onSectionSelected(_AdminSection.overview);
            },
          ),

          _AdminNavItem(
            icon: Icons.people_outline,
            label: 'Accounts',
            selected: selectedSection == _AdminSection.accounts,
            onTap: () {
              onSectionSelected(_AdminSection.accounts);
            },
          ),

          _AdminNavItem(
            icon: Icons.analytics_outlined,
            label: 'Classifications',
            selected: selectedSection == _AdminSection.classifications,
            onTap: () {
              onSectionSelected(_AdminSection.classifications);
            },
          ),

          const Spacer(),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 125,
              width: double.infinity,
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
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(11),
                      child: Text(
                        'ADMIN\nCONTROL',
                        style: AppTypography.label.copyWith(
                          color: AppColors.fiberBeige,
                          fontSize: 9,
                          letterSpacing: 1.3,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          _AdminNavItem(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.38),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
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
// MOBILE DRAWER
// ============================================================

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
    required this.selectedSection,
    required this.onSectionSelected,
    required this.onLogout,
  });

  final _AdminSection selectedSection;

  final void Function(_AdminSection section) onSectionSelected;

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.primaryDark,
              child: const _Brand(),
            ),

            const SizedBox(height: 12),

            _DrawerItem(
              icon: Icons.dashboard_outlined,
              label: 'Admin Dashboard',
              selected: selectedSection == _AdminSection.overview,
              onTap: () {
                Navigator.pop(context);

                onSectionSelected(_AdminSection.overview);
              },
            ),

            _DrawerItem(
              icon: Icons.people_outline,
              label: 'Accounts',
              selected: selectedSection == _AdminSection.accounts,
              onTap: () {
                Navigator.pop(context);

                onSectionSelected(_AdminSection.accounts);
              },
            ),

            _DrawerItem(
              icon: Icons.analytics_outlined,
              label: 'Classifications',
              selected: selectedSection == _AdminSection.classifications,
              onTap: () {
                Navigator.pop(context);

                onSectionSelected(_AdminSection.classifications);
              },
            ),

            const Spacer(),
            const Divider(),

            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              onTap: () async {
                Navigator.pop(context);
                await onLogout();
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        selected: selected,
        selectedColor: AppColors.primaryDark,
        selectedTileColor: AppColors.primarySoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon),
        title: Text(label),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// CREATE ADMIN
// ============================================================

class _CreateAdminDialog extends StatefulWidget {
  const _CreateAdminDialog();

  @override
  State<_CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends State<_CreateAdminDialog> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final token = context.read<AuthProvider>().token;

    if (token == null || token.trim().isEmpty) {
      return;
    }

    final adminProvider = context.read<AdminProvider>();

    final success = await adminProvider.createAdministrator(
      token: token,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      actionsPadding: const EdgeInsets.all(20),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Create Administrator')),
        ],
      ),
      content: SizedBox(
        width: 470,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create an additional authorized ABAKASCAN administrator account.',
                  style: AppTypography.bodySecondary,
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _fullNameController,
                  enabled: !admin.creatingAdmin,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailController,
                  enabled: !admin.creatingAdmin,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
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

                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordController,
                  enabled: !admin.creatingAdmin,
                  obscureText: _obscurePassword,
                  onFieldSubmitted: (_) {
                    if (!admin.creatingAdmin) {
                      _submit();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: admin.creatingAdmin
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                      icon: Icon(
                        _obscurePassword
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

                if (admin.createAdminError != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      admin.createAdminError!,
                      style: AppTypography.bodySecondary.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This creates an ADMIN authorization account. '
                          'It does not assign a farmer, processor, cooperative, buyer, '
                          'researcher, or other stakeholder role.',
                          style: AppTypography.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: admin.creatingAdmin
              ? null
              : () {
                  context.read<AdminProvider>().clearCreateAdminError();

                  Navigator.pop(context, false);
                },
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
          onPressed: admin.creatingAdmin ? null : _submit,
          icon: admin.creatingAdmin
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.person_add_alt_1_outlined),
          label: Text(
            admin.creatingAdmin ? 'Creating...' : 'Create Administrator',
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CLASSIFICATION DETAILS DIALOG
// ============================================================

void _showClassificationDetails(
  BuildContext context,
  AdminClassificationRecordModel record,
) {
  final confidence = _confidence(record.confidencePercentage);

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(child: Text('Classification Details')),
          ],
        ),
        content: SizedBox(
          width: 470,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREDICTED GRADE',
                        style: AppTypography.label.copyWith(
                          color: AppColors.primary,
                          fontSize: 9,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        record.predictedGrade,
                        style: AppTypography.pageTitle.copyWith(
                          color: AppColors.primaryDark,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _DialogDetail(
                  label: 'Confidence',
                  value: '${confidence.toStringAsFixed(1)}%',
                ),

                const SizedBox(height: 14),

                _DialogDetail(
                  label: 'Record ID',
                  value: record.id,
                  selectable: true,
                ),

                const SizedBox(height: 14),

                _DialogDetail(label: 'Account', value: record.ownerDisplayName),

                if (record.userEmail != null &&
                    record.userEmail!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _DialogDetail(
                    label: 'User Email',
                    value: record.userEmail!,
                    selectable: true,
                  ),
                ],

                const SizedBox(height: 14),

                _DialogDetail(
                  label: 'Date',
                  value: _formatDateTime(record.createdAt),
                ),

                if (record.modelName != null &&
                    record.modelName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _DialogDetail(label: 'Model', value: record.modelName!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class _DialogDetail extends StatelessWidget {
  const _DialogDetail({
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;

  final bool selectable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        if (selectable)
          SelectableText(
            value,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          )
        else
          Text(
            value,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

// ============================================================
// BRAND
// ============================================================

class _Brand extends StatelessWidget {
  const _Brand({this.darkText = false});

  final bool darkText;

  @override
  Widget build(BuildContext context) {
    final textColor = darkText ? AppColors.primaryDark : Colors.white;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.eco_outlined,
          color: darkText ? AppColors.primary : AppColors.fiberBeige,
          size: 24,
        ),
        const SizedBox(width: 9),
        Text(
          'ABAKASCAN',
          style: AppTypography.label.copyWith(
            color: textColor,
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
// FIBER DECORATION
// ============================================================

class _FiberLinePainter extends CustomPainter {
  const _FiberLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < 10; index++) {
      final y = size.height * (0.34 + index * 0.027);

      final path = Path()
        ..moveTo(-20, y)
        ..cubicTo(
          size.width * 0.28,
          y + 42,
          size.width * 0.67,
          y - 35,
          size.width + 28,
          y + 7,
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

double _confidence(double value) {
  if (value <= 1) {
    return (value * 100).clamp(0.0, 100.0).toDouble();
  }

  return value.clamp(0.0, 100.0).toDouble();
}

String _shortId(String id) {
  final value = id.trim();

  if (value.length <= 8) {
    return value;
  }

  return value.substring(0, 8);
}

String _formatDate(DateTime date) {
  final local = date.toLocal();

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[local.month - 1]} '
      '${local.day}, ${local.year}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();

  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;

  final minute = local.minute.toString().padLeft(2, '0');

  final period = local.hour >= 12 ? 'PM' : 'AM';

  return '${_formatDate(local)} • '
      '$hour:$minute $period';
}
