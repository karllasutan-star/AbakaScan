import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';

import 'about_screen.dart';
import 'classify_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'samples_screen.dart';
import 'settings_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _historyRequested = false;

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

  void _returnDashboard() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openClassify() async {
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

  Future<void> _openProfile() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  Future<void> _openSamples() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SamplesScreen()));
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
                  child: _ReportsSidebar(
                    onDashboard: _returnDashboard,
                    onClassify: _openClassify,
                    onHistory: _openHistory,
                    onSamples: _openSamples,
                    onSettings: _openSettings,
                    onAbout: _openAbout,
                    onLogout: _logout,
                  ),
                ),
                Expanded(
                  child: _ReportsBody(
                    onRefresh: _refreshHistory,
                    onClassify: _openClassify,
                    onHistory: _openHistory,
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
                  _returnDashboard();
                }
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text('Reports', style: AppTypography.cardTitle),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refreshHistory,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: _ReportsBody(
            onRefresh: _refreshHistory,
            onClassify: _openClassify,
            onHistory: _openHistory,
            compact: true,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 2,
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
                icon: Icon(Icons.bar_chart_rounded),
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
                  _returnDashboard();
                  break;

                case 1:
                  _openHistory();
                  break;

                case 2:
                  break;

                case 3:
                  _openProfile();
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

class _ReportsBody extends StatelessWidget {
  const _ReportsBody({
    required this.onRefresh,
    required this.onClassify,
    required this.onHistory,
    this.compact = false,
  });

  final Future<void> Function() onRefresh;

  final Future<void> Function() onClassify;

  final Future<void> Function() onHistory;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    final records = [...history.records]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final analytics = _ReportAnalytics.from(records);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 28,
          compact ? 8 : 26,
          compact ? 16 : 28,
          36,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact) const _DesktopHeader(),

                if (!compact) const SizedBox(height: 22),

                if (compact) const _MobileHeader(),

                if (compact) const SizedBox(height: 15),

                if (history.isLoading && records.isEmpty)
                  const _LoadingState()
                else if (history.error != null && records.isEmpty)
                  _ErrorState(message: history.error!, onRetry: onRefresh)
                else if (records.isEmpty)
                  _EmptyReports(onClassify: onClassify)
                else ...[
                  _SummaryCards(analytics: analytics),

                  const SizedBox(height: 18),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 850;

                      final distribution = _GradeDistribution(
                        analytics: analytics,
                      );

                      final confidence = _ConfidencePanel(analytics: analytics);

                      if (stacked) {
                        return Column(
                          children: [
                            distribution,
                            const SizedBox(height: 14),
                            confidence,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: distribution),
                          const SizedBox(width: 16),
                          Expanded(flex: 4, child: confidence),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  _RecentActivity(
                    records: records.take(5).toList(),
                    onHistory: onHistory,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HEADERS
// ============================================================

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANALYTICS',
          style: AppTypography.label.copyWith(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Classification Reports',
          style: AppTypography.pageTitle.copyWith(fontSize: 34),
        ),
        const SizedBox(height: 7),
        Text(
          'A summary of your saved ABAKASCAN classification records.',
          style: AppTypography.bodySecondary.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 175,
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
                  Color(0xF20F3D2E),
                  Color(0xB80F3D2E),
                  Color(0x330F3D2E),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your Fiber\nInsights',
                  style: AppTypography.pageTitle.copyWith(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1.04,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Analytics based on your saved classifications.',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.74),
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
// SUMMARY
// ============================================================

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.analytics});

  final _ReportAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryData(
        icon: Icons.analytics_outlined,
        label: 'Total Analyses',
        value: analytics.total.toString(),
      ),
      _SummaryData(
        icon: Icons.center_focus_strong_outlined,
        label: 'Average Confidence',
        value: '${analytics.averageConfidence.toStringAsFixed(1)}%',
      ),
      _SummaryData(
        icon: Icons.workspace_premium_outlined,
        label: 'Most Common Grade',
        value: analytics.mostCommonGrade,
      ),
      _SummaryData(
        icon: Icons.calendar_month_outlined,
        label: 'This Month',
        value: analytics.thisMonth.toString(),
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
              return _SummaryCard(data: cards[index]);
            },
          );
        }

        return Row(
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(child: _SummaryCard(data: cards[index])),
              if (index < cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryData {
  const _SummaryData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryData data;

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
            child: Icon(data.icon, size: 19, color: AppColors.primary),
          ),
          const Spacer(),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sectionTitle.copyWith(
              color: AppColors.primaryDark,
              fontSize: 20,
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
// GRADE DISTRIBUTION
// ============================================================

class _GradeDistribution extends StatelessWidget {
  const _GradeDistribution({required this.analytics});

  final _ReportAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      title: 'Grade Distribution',
      subtitle: 'Breakdown of your saved predicted grades.',
      child: Column(
        children: [
          for (
            var index = 0;
            index < analytics.gradeDistribution.length;
            index++
          ) ...[
            _DistributionRow(
              entry: analytics.gradeDistribution[index],
              total: analytics.total,
            ),
            if (index < analytics.gradeDistribution.length - 1)
              const SizedBox(height: 15),
          ],
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({required this.entry, required this.total});

  final MapEntry<String, int> entry;

  final int total;

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0.0 : entry.value / total;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.key,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitle.copyWith(fontSize: 13),
              ),
            ),
            Text(
              '${entry.value}',
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 45,
              child: Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: AppTypography.caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: AppColors.surfaceSage,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CONFIDENCE
// ============================================================

class _ConfidencePanel extends StatelessWidget {
  const _ConfidencePanel({required this.analytics});

  final _ReportAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      title: 'Confidence Summary',
      subtitle: 'Confidence values from your saved records.',
      child: Column(
        children: [
          _ConfidenceMetric(
            icon: Icons.trending_up_rounded,
            title: 'Highest Confidence',
            value: '${analytics.highestConfidence.toStringAsFixed(1)}%',
          ),

          const SizedBox(height: 18),

          _ConfidenceMetric(
            icon: Icons.show_chart_rounded,
            title: 'Average Confidence',
            value: '${analytics.averageConfidence.toStringAsFixed(1)}%',
          ),

          const SizedBox(height: 18),

          _ConfidenceMetric(
            icon: Icons.trending_down_rounded,
            title: 'Lowest Confidence',
            value: '${analytics.lowestConfidence.toStringAsFixed(1)}%',
          ),

          const SizedBox(height: 22),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latest Grade', style: AppTypography.caption),
                const SizedBox(height: 5),
                Text(
                  analytics.latestGrade,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 20,
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

class _ConfidenceMetric extends StatelessWidget {
  const _ConfidenceMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.caption),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// RECENT ACTIVITY
// ============================================================

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.records, required this.onHistory});

  final List<ClassificationRecordModel> records;

  final Future<void> Function() onHistory;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      title: 'Recent Activity',
      subtitle: 'Your latest saved classification records.',
      trailing: TextButton(
        onPressed: onHistory,
        child: const Text('View History →'),
      ),
      child: Column(
        children: [
          for (var index = 0; index < records.length; index++) ...[
            _ActivityRow(record: records[index]),
            if (index < records.length - 1) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.record});

  final ClassificationRecordModel record;

  @override
  Widget build(BuildContext context) {
    final confidence = _confidence(record.confidencePercentage);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.analytics_outlined,
            size: 20,
            color: AppColors.primary,
          ),
        ),

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
                _formatDateTime(record.createdAt),
                style: AppTypography.caption,
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                record.predictedGrade,
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
            ),
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
// PANEL BASE
// ============================================================

class _ReportPanel extends StatelessWidget {
  const _ReportPanel({
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

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY / LOADING / ERROR
// ============================================================

class _EmptyReports extends StatelessWidget {
  const _EmptyReports({required this.onClassify});

  final Future<void> Function() onClassify;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 58),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: AppColors.primaryDark,
              size: 31,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No report data yet',
            style: AppTypography.sectionTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 7),
          const Text(
            'Reports are created from your saved classification history. Analyze a fiber image to begin.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
            ),
            onPressed: onClassify,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Analyze Fiber'),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(strokeWidth: 2.5),
          SizedBox(height: 14),
          Text('Loading report data...', style: AppTypography.bodySecondary),
        ],
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
          const Icon(Icons.error_outline, color: AppColors.error, size: 30),
          const SizedBox(height: 11),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SIDEBAR
// ============================================================

class _ReportsSidebar extends StatelessWidget {
  const _ReportsSidebar({
    required this.onDashboard,
    required this.onClassify,
    required this.onHistory,
    required this.onSamples,
    required this.onSettings,
    required this.onAbout,
    required this.onLogout,
  });

  final VoidCallback onDashboard;

  final Future<void> Function() onClassify;

  final Future<void> Function() onHistory;

  final Future<void> Function() onSamples;

  final Future<void> Function() onSettings;

  final Future<void> Function() onAbout;

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

          const _SidebarItem(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
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
// ANALYTICS
// ============================================================

class _ReportAnalytics {
  const _ReportAnalytics({
    required this.total,
    required this.averageConfidence,
    required this.highestConfidence,
    required this.lowestConfidence,
    required this.thisMonth,
    required this.latestGrade,
    required this.mostCommonGrade,
    required this.gradeDistribution,
  });

  final int total;

  final double averageConfidence;
  final double highestConfidence;
  final double lowestConfidence;

  final int thisMonth;

  final String latestGrade;
  final String mostCommonGrade;

  final List<MapEntry<String, int>> gradeDistribution;

  factory _ReportAnalytics.from(List<ClassificationRecordModel> records) {
    if (records.isEmpty) {
      return const _ReportAnalytics(
        total: 0,
        averageConfidence: 0,
        highestConfidence: 0,
        lowestConfidence: 0,
        thisMonth: 0,
        latestGrade: '—',
        mostCommonGrade: '—',
        gradeDistribution: [],
      );
    }

    final gradeCounts = <String, int>{};

    var totalConfidence = 0.0;
    var highestConfidence = 0.0;
    var lowestConfidence = 100.0;
    var thisMonth = 0;

    final now = DateTime.now();

    for (final record in records) {
      final confidence = _confidence(record.confidencePercentage);

      totalConfidence += confidence;

      if (confidence > highestConfidence) {
        highestConfidence = confidence;
      }

      if (confidence < lowestConfidence) {
        lowestConfidence = confidence;
      }

      final grade = record.predictedGrade.trim();

      if (grade.isNotEmpty) {
        gradeCounts[grade] = (gradeCounts[grade] ?? 0) + 1;
      }

      final date = record.createdAt.toLocal();

      if (date.year == now.year && date.month == now.month) {
        thisMonth++;
      }
    }

    final distribution = gradeCounts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);

        if (countCompare != 0) {
          return countCompare;
        }

        return a.key.compareTo(b.key);
      });

    final mostCommonGrade = distribution.isEmpty ? '—' : distribution.first.key;

    return _ReportAnalytics(
      total: records.length,
      averageConfidence: totalConfidence / records.length,
      highestConfidence: highestConfidence,
      lowestConfidence: lowestConfidence,
      thisMonth: thisMonth,
      latestGrade: records.first.predictedGrade,
      mostCommonGrade: mostCommonGrade,
      gradeDistribution: distribution,
    );
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

String _formatDateTime(DateTime date) {
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
