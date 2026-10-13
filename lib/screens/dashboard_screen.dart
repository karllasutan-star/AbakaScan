import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../services/api_services.dart';

import 'about_screen.dart';
import 'classify_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'samples_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _historyRequested = false;
  String _search = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_historyRequested) {
      return;
    }

    _historyRequested = true;
    Future.microtask(_loadHistory);
  }

  Future<void> _loadHistory() async {
    final token = context.read<AuthProvider>().token;

    if (token == null || token.trim().isEmpty) {
      return;
    }

    final history = context.read<HistoryProvider>();

    await history.loadHistory(token: token);

    if (!mounted) {
      return;
    }

    if (history.sessionExpired) {
      await _handleExpiredSession();
    }
  }

  Future<void> _refreshHistory() async {
    final token = context.read<AuthProvider>().token;

    if (token == null || token.trim().isEmpty) {
      return;
    }

    final history = context.read<HistoryProvider>();

    await history.refreshHistory(token: token);

    if (!mounted) {
      return;
    }

    if (history.sessionExpired) {
      await _handleExpiredSession();
    }
  }

  Future<void> _handleExpiredSession() async {
    context.read<ImageSelectionProvider>().removeImage();
    context.read<ClassificationProvider>().reset();
    context.read<HistoryProvider>().reset();
    context.read<AdminProvider>().reset();

    await context.read<AuthProvider>().expireSession();

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openAnalyze() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ClassifyScreen()));

    if (!mounted) {
      return;
    }

    await _refreshHistory();
  }

  Future<void> _openHistory() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HistoryScreen()));

    if (!mounted) {
      return;
    }

    await _refreshHistory();
  }

  Future<void> _openSamples() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SamplesScreen()));
  }

  Future<void> _openReports() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
  }

  Future<void> _openProfile() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  Future<void> _openSettings() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _openAbout() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AboutScreen()));
  }

  Future<void> _logout() async {
    context.read<ImageSelectionProvider>().removeImage();
    context.read<ClassificationProvider>().reset();
    context.read<HistoryProvider>().reset();
    context.read<AdminProvider>().reset();

    await context.read<AuthProvider>().logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

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
                  child: _Sidebar(
                    onAnalyze: _openAnalyze,
                    onHistory: _openHistory,
                    onSamples: _openSamples,
                    onReports: _openReports,
                    onSettings: _openSettings,
                  ),
                ),

                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        user: user,
                        onSearch: (value) {
                          setState(() {
                            _search = value;
                          });
                        },
                        onProfile: _openProfile,
                        onAbout: _openAbout,
                        onLogout: _logout,
                      ),

                      Expanded(
                        child: _DesktopBody(
                          search: _search,
                          onAnalyze: _openAnalyze,
                          onHistory: _openHistory,
                          onRefresh: _refreshHistory,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return _MobileHome(
          user: user,
          onAnalyze: _openAnalyze,
          onHistory: _openHistory,
          onReports: _openReports,
          onProfile: _openProfile,
          onRefresh: _refreshHistory,
        );
      },
    );
  }
}

// ============================================================
// SIDEBAR
// ============================================================

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.onAnalyze,
    required this.onHistory,
    required this.onSamples,
    required this.onReports,
    required this.onSettings,
  });

  final VoidCallback onAnalyze;
  final VoidCallback onHistory;
  final VoidCallback onSamples;
  final VoidCallback onReports;
  final VoidCallback onSettings;

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

          const _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            selected: true,
          ),

          _NavItem(
            icon: Icons.camera_alt_outlined,
            label: 'Analyze',
            onTap: onAnalyze,
          ),

          _NavItem(
            icon: Icons.history_rounded,
            label: 'History',
            onTap: onHistory,
          ),

          _NavItem(
            icon: Icons.inventory_2_outlined,
            label: 'Samples',
            onTap: onSamples,
          ),

          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            onTap: onReports,
          ),

          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: onSettings,
          ),

          const Spacer(),

          Opacity(
            opacity: 0.34,
            child: Image.asset(
              'assets/images/abakascan_auth_hero.png',
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'FIBER INTELLIGENCE',
            textAlign: TextAlign.center,
            style: AppTypography.label.copyWith(
              color: AppColors.fiberBeige,
              fontSize: 9,
              letterSpacing: 1.8,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'FOR A STRONGER TOMORROW',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
        : Colors.white.withValues(alpha: 0.75);

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
// TOP BAR
// ============================================================

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.user,
    required this.onSearch,
    required this.onProfile,
    required this.onAbout,
    required this.onLogout,
  });

  final UserModel? user;

  final ValueChanged<String> onSearch;

  final VoidCallback onProfile;
  final VoidCallback onAbout;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final rawName = user?.fullName.trim();

    final name = rawName == null || rawName.isEmpty ? 'User' : rawName;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 365,
            child: TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Search your analyses...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          const Spacer(),

          Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textSecondary,
            size: 21,
          ),

          const SizedBox(width: 18),

          PopupMenuButton<_AccountAction>(
            tooltip: 'Account',
            onSelected: (action) {
              switch (action) {
                case _AccountAction.profile:
                  onProfile();
                  break;

                case _AccountAction.about:
                  onAbout();
                  break;

                case _AccountAction.logout:
                  onLogout();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _AccountAction.profile,
                child: Text('Profile'),
              ),

              PopupMenuItem(value: _AccountAction.about, child: Text('About')),

              PopupMenuDivider(),

              PopupMenuItem(
                value: _AccountAction.logout,
                child: Text('Log Out'),
              ),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.surfaceSage,
                  child: Text(
                    _initials(name),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 9),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 145),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _AccountAction { profile, about, logout }

// ============================================================
// DESKTOP BODY
// ============================================================

class _DesktopBody extends StatelessWidget {
  const _DesktopBody({
    required this.search,
    required this.onAnalyze,
    required this.onHistory,
    required this.onRefresh,
  });

  final String search;

  final Future<void> Function() onAnalyze;
  final Future<void> Function() onHistory;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    final records = [...history.records]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final query = search.trim().toLowerCase();

    final filtered = query.isEmpty
        ? records
        : records.where((record) {
            return record.predictedGrade.toLowerCase().contains(query) ||
                record.id.toLowerCase().contains(query);
          }).toList();

    final analytics = _DashboardStats.from(records);

    final latest = records.isEmpty ? null : records.first;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1260),
            child: Column(
              children: [
                _Hero(onAnalyze: onAnalyze),

                const SizedBox(height: 15),

                _Workflow(onAnalyze: onAnalyze, onHistory: onHistory),

                const SizedBox(height: 18),

                if (history.isLoading && records.isEmpty)
                  const _LoadingState()
                else if (history.error != null && records.isEmpty)
                  _ErrorState(message: history.error!, onRetry: onRefresh)
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 980;

                      final overview = _OverviewPanel(stats: analytics);

                      final recent = _RecentPanel(
                        records: filtered.take(4).toList(),
                        searching: query.isNotEmpty,
                        onViewAll: onHistory,
                      );

                      final latestResult = _LatestResultPanel(
                        record: latest,
                        onOpenHistory: onHistory,
                      );

                      if (compact) {
                        return Column(
                          children: [
                            overview,

                            const SizedBox(height: 16),

                            recent,

                            const SizedBox(height: 16),

                            latestResult,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: overview),

                          const SizedBox(width: 16),

                          Expanded(flex: 5, child: recent),

                          const SizedBox(width: 16),

                          Expanded(flex: 4, child: latestResult),
                        ],
                      );
                    },
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _Hero extends StatelessWidget {
  const _Hero({required this.onAnalyze});

  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 205,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
                    Color(0xF20B392B),
                    Color(0xD00B392B),
                    Color(0x700B392B),
                    Color(0x160B392B),
                  ],
                ),
              ),
            ),

            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _GoldLinePainter()),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 23, 28, 23),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Brand(),

                        const Spacer(),

                        Text(
                          'See the quality\nin every fiber.',
                          style: AppTypography.pageTitle.copyWith(
                            color: Colors.white,
                            fontSize: 31,
                            height: 1.02,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          'Fiber intelligence for a stronger tomorrow.',
                          style: AppTypography.bodySecondary.copyWith(
                            color: Colors.white.withValues(alpha: 0.73),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Align(
                    alignment: Alignment.bottomRight,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.fiberBeige,
                        foregroundColor: AppColors.primaryDark,
                      ),
                      onPressed: onAnalyze,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Analyze Fiber'),
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
// WORKFLOW
// ============================================================

class _Workflow extends StatelessWidget {
  const _Workflow({required this.onAnalyze, required this.onHistory});

  final VoidCallback onAnalyze;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    const items = [
      _WorkflowItemData(
        number: '1',
        icon: Icons.upload_file_outlined,
        title: 'Upload / Capture',
        description: 'Add your fiber image.',
      ),

      _WorkflowItemData(
        number: '2',
        icon: Icons.auto_awesome_outlined,
        title: 'Analyze',
        description: 'Run classification.',
      ),

      _WorkflowItemData(
        number: '3',
        icon: Icons.analytics_outlined,
        title: 'Results',
        description: 'Review grade & confidence.',
      ),

      _WorkflowItemData(
        number: '4',
        icon: Icons.history_outlined,
        title: 'History',
        description: 'View saved analyses.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 110,
            ),
            itemBuilder: (context, index) {
              return _WorkflowCard(
                data: items[index],
                onTap: index == 3 ? onHistory : onAnalyze,
              );
            },
          );
        }

        return Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(
                child: _WorkflowCard(
                  data: items[index],
                  onTap: index == 3 ? onHistory : onAnalyze,
                ),
              ),

              if (index < items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                    color: AppColors.textSecondary.withValues(alpha: 0.65),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _WorkflowItemData {
  const _WorkflowItemData({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.data, required this.onTap});

  final _WorkflowItemData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, size: 20, color: AppColors.primaryDark),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.number}. ${data.title}',
                      style: AppTypography.cardTitle.copyWith(fontSize: 13),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      data.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PANEL BASE
// ============================================================

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 320),
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
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(fontSize: 15),
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

// ============================================================
// OVERVIEW
// ============================================================

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.stats});

  final _DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Overview',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'All time',
          style: AppTypography.caption.copyWith(fontSize: 9),
        ),
      ),
      child: Column(
        children: [
          _Metric(
            icon: Icons.analytics_outlined,
            value: stats.total.toString(),
            label: 'Total Analyses',
          ),

          const SizedBox(height: 16),

          _Metric(
            icon: Icons.center_focus_strong_outlined,
            value: '${stats.averageConfidence.toStringAsFixed(0)}%',
            label: 'Average Confidence',
          ),

          const SizedBox(height: 16),

          _Metric(
            icon: Icons.category_outlined,
            value: stats.uniqueGrades.toString(),
            label: 'Fiber Grades',
          ),

          const SizedBox(height: 16),

          _Metric(
            icon: Icons.calendar_month_outlined,
            value: stats.thisMonth.toString(),
            label: 'This Month',
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
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
              Text(
                value,
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 17,
                ),
              ),

              Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// RECENT
// ============================================================

class _RecentPanel extends StatelessWidget {
  const _RecentPanel({
    required this.records,
    required this.searching,
    required this.onViewAll,
  });

  final List<ClassificationRecordModel> records;
  final bool searching;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: searching ? 'Search Results' : 'Recent Analyses',
      trailing: TextButton(
        onPressed: onViewAll,
        child: const Text('View all →'),
      ),
      child: records.isEmpty
          ? SizedBox(
              height: 210,
              child: Center(
                child: Text(
                  searching
                      ? 'No analyses match your search.'
                      : 'No analyses yet.',
                  style: AppTypography.bodySecondary,
                ),
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < records.length; index++) ...[
                  _RecentRow(record: records[index]),

                  if (index < records.length - 1) const Divider(height: 20),
                ],
              ],
            ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.record});

  final ClassificationRecordModel record;

  @override
  Widget build(BuildContext context) {
    final confidence = _confidence(record.confidencePercentage);

    return Row(
      children: [
        _Thumbnail(record: record, width: 52, height: 52),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis ${_shortId(record.id)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitle.copyWith(fontSize: 13),
              ),

              const SizedBox(height: 3),

              Text(
                _date(record.createdAt),
                style: AppTypography.caption.copyWith(fontSize: 9),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _GradeChip(grade: record.predictedGrade),

            const SizedBox(height: 5),

            Text(
              '${confidence.toStringAsFixed(0)}%',
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// LATEST RESULT
// ============================================================

class _LatestResultPanel extends StatelessWidget {
  const _LatestResultPanel({required this.record, required this.onOpenHistory});

  final ClassificationRecordModel? record;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Latest Result',
      trailing: record == null
          ? null
          : TextButton(
              onPressed: onOpenHistory,
              child: const Text('View details →'),
            ),
      child: record == null
          ? const SizedBox(
              height: 210,
              child: Center(
                child: Text(
                  'Your latest result will appear here.',
                  style: AppTypography.bodySecondary,
                ),
              ),
            )
          : _LatestContent(record: record!),
    );
  }
}

class _LatestContent extends StatelessWidget {
  const _LatestContent({required this.record});

  final ClassificationRecordModel record;

  @override
  Widget build(BuildContext context) {
    final confidence = _confidence(record.confidencePercentage);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(record: record, width: 102, height: 142),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analysis ${_shortId(record.id)}',
                    style: AppTypography.cardTitle.copyWith(fontSize: 13),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _date(record.createdAt),
                    style: AppTypography.caption.copyWith(fontSize: 9),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      record.predictedGrade,
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text('Confidence', style: AppTypography.caption),

                      const Spacer(),

                      Text(
                        '${confidence.toStringAsFixed(0)}%',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: confidence / 100,
                      minHeight: 7,
                      backgroundColor: AppColors.surfaceSage,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 10),

        Row(
          children: [
            const Icon(
              Icons.fact_check_outlined,
              size: 18,
              color: AppColors.primary,
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Text(
                'Latest saved classification result',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// MOBILE HOME
// ============================================================

class _MobileHome extends StatelessWidget {
  const _MobileHome({
    required this.user,
    required this.onAnalyze,
    required this.onHistory,
    required this.onReports,
    required this.onProfile,
    required this.onRefresh,
  });

  final UserModel? user;

  final Future<void> Function() onAnalyze;
  final Future<void> Function() onHistory;
  final Future<void> Function() onReports;
  final Future<void> Function() onProfile;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final rawName = user?.fullName.trim();

    final name = rawName == null || rawName.isEmpty ? 'User' : rawName;

    final firstName = name.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        _Brand(darkText: true),

                        Spacer(),

                        Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.primaryDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    _MobileHero(firstName: firstName),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _MobileActionCard(
                            icon: Icons.photo_library_outlined,
                            title: 'Upload Photo',
                            subtitle: 'Choose an image',
                            onTap: onAnalyze,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _MobileActionCard(
                            icon: Icons.camera_alt_outlined,
                            title: 'Capture',
                            subtitle: 'Take a photo',
                            onTap: onAnalyze,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _ClassifyButton(onTap: onAnalyze),

                    const SizedBox(height: 26),

                    _MobileRecent(onHistory: onHistory),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
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
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break;

            case 1:
              onHistory();
              break;

            case 2:
              onReports();
              break;

            case 3:
              onProfile();
              break;
          }
        },
      ),
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 225,
      width: double.infinity,
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
                    Color(0xF60B392B),
                    Color(0xC00B392B),
                    Color(0x160B392B),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good day,\n$firstName!',
                    style: AppTypography.pageTitle.copyWith(
                      color: Colors.white,
                      fontSize: 30,
                      height: 1.03,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'See the quality\nin every fiber.',
                    style: AppTypography.bodySecondary.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.4,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    'FIBER INTELLIGENCE',
                    style: AppTypography.label.copyWith(
                      color: AppColors.fiberBeige,
                      fontSize: 9,
                      letterSpacing: 1.7,
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

class _MobileActionCard extends StatelessWidget {
  const _MobileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 118,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),

              const SizedBox(height: 9),

              Text(
                title,
                style: AppTypography.cardTitle.copyWith(fontSize: 13),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                style: AppTypography.caption.copyWith(fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassifyButton extends StatelessWidget {
  const _ClassifyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.fiberBeige.withValues(alpha: 0.18),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.fiberBeige,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Classify Fiber',
                      style: AppTypography.cardTitle.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Analyze your abaca fiber image',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileRecent extends StatelessWidget {
  const _MobileRecent({required this.onHistory});

  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    final records = [...history.records]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Recent Analyses', style: AppTypography.sectionTitle),
            ),

            TextButton(onPressed: onHistory, child: const Text('View all')),
          ],
        ),

        const SizedBox(height: 8),

        if (records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Your recent analyses will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary,
            ),
          )
        else
          for (final record in records.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MobileRecord(record: record),
            ),
      ],
    );
  }
}

class _MobileRecord extends StatelessWidget {
  const _MobileRecord({required this.record});

  final ClassificationRecordModel record;

  @override
  Widget build(BuildContext context) {
    final confidence = _confidence(record.confidencePercentage);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Thumbnail(record: record, width: 58, height: 58),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis ${_shortId(record.id)}',
                  style: AppTypography.cardTitle.copyWith(fontSize: 13),
                ),

                const SizedBox(height: 3),

                Text(
                  _date(record.createdAt),
                  style: AppTypography.caption.copyWith(fontSize: 9),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _GradeChip(grade: record.predictedGrade),

              const SizedBox(height: 5),

              Text(
                '${confidence.toStringAsFixed(0)}%',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// THUMBNAIL
// ============================================================

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.record,
    required this.width,
    required this.height,
  });

  final ClassificationRecordModel record;

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl(record.imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        width: width,
        height: height,
        child: url == null
            ? Image.asset(
                'assets/images/abakascan_auth_hero.png',
                fit: BoxFit.cover,
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/abakascan_auth_hero.png',
                    fit: BoxFit.cover,
                  );
                },
              ),
      ),
    );
  }
}

// ============================================================
// GRADE CHIP
// ============================================================

class _GradeChip extends StatelessWidget {
  const _GradeChip({required this.grade});

  final String grade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        grade,
        style: AppTypography.caption.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}

// ============================================================
// LOADING / ERROR
// ============================================================

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),

            SizedBox(height: 14),

            Text('Loading dashboard...', style: AppTypography.bodySecondary),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),

          const SizedBox(height: 10),

          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary,
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
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
    final foreground = darkText ? AppColors.primaryDark : Colors.white;

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
            color: foreground,
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
// STATS
// ============================================================

class _DashboardStats {
  const _DashboardStats({
    required this.total,
    required this.averageConfidence,
    required this.uniqueGrades,
    required this.thisMonth,
  });

  final int total;
  final double averageConfidence;
  final int uniqueGrades;
  final int thisMonth;

  factory _DashboardStats.from(List<ClassificationRecordModel> records) {
    if (records.isEmpty) {
      return const _DashboardStats(
        total: 0,
        averageConfidence: 0,
        uniqueGrades: 0,
        thisMonth: 0,
      );
    }

    var totalConfidence = 0.0;
    var monthCount = 0;

    final grades = <String>{};

    final now = DateTime.now();

    for (final record in records) {
      totalConfidence += _confidence(record.confidencePercentage);

      grades.add(record.predictedGrade.trim().toLowerCase());

      final date = record.createdAt.toLocal();

      if (date.year == now.year && date.month == now.month) {
        monthCount++;
      }
    }

    return _DashboardStats(
      total: records.length,
      averageConfidence: totalConfidence / records.length,
      uniqueGrades: grades.length,
      thisMonth: monthCount,
    );
  }
}

// ============================================================
// DECORATIVE LINES
// ============================================================

class _GoldLinePainter extends CustomPainter {
  const _GoldLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < 10; index++) {
      final y = size.height * (0.30 + index * 0.025);

      final path = Path()
        ..moveTo(size.width * 0.34, y)
        ..cubicTo(
          size.width * 0.55,
          y + 30,
          size.width * 0.69,
          y - 36,
          size.width + 20,
          y + 10,
        );

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = index % 3 == 0 ? 1.2 : 0.7
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

  if (value.length <= 6) {
    return value;
  }

  return value.substring(0, 6);
}

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

String? _imageUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }

  final value = raw.trim();

  final uri = Uri.tryParse(value);

  if (uri != null && uri.hasScheme) {
    return value;
  }

  var base = ApiConfig.baseUrl;

  if (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }

  final path = value.startsWith('/') ? value : '/$value';

  return '$base$path';
}

String _date(DateTime value) {
  final local = value.toLocal();

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

  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;

  final minute = local.minute.toString().padLeft(2, '0');

  final period = local.hour >= 12 ? 'PM' : 'AM';

  return '${months[local.month - 1]} '
      '${local.day}, ${local.year} • '
      '$hour:$minute $period';
}
