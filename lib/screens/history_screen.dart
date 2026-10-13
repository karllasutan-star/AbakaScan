import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../services/api_services.dart';

import 'about_screen.dart';
import 'classification_details_screen.dart';
import 'classify_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'samples_screen.dart';
import 'settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _historyRequested = false;

  String _search = '';
  String _selectedGrade = 'All';

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

  Future<void> _openDetails(ClassificationRecordModel record) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClassificationDetailsScreen(
          record: record,
          onDelete: _deleteFromDetails,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _refreshHistory();
  }

  Future<bool> _deleteFromDetails(ClassificationRecordModel record) async {
    final token = context.read<AuthProvider>().token;

    if (token == null || token.trim().isEmpty) {
      return false;
    }

    final history = context.read<HistoryProvider>();

    final deleted = await history.deleteClassification(
      token: token,
      classificationId: record.id,
    );

    if (!mounted) {
      return deleted;
    }

    if (history.sessionExpired) {
      await _handleExpiredSession();
      return false;
    }

    return deleted;
  }

  Future<void> _openReports() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
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
                  child: _HistorySidebar(
                    onDashboard: _returnDashboard,
                    onClassify: _openClassify,
                    onSamples: _openSamples,
                    onReports: _openReports,
                    onSettings: _openSettings,
                    onAbout: _openAbout,
                    onLogout: _logout,
                  ),
                ),
                Expanded(
                  child: _HistoryBody(
                    search: _search,
                    selectedGrade: _selectedGrade,
                    onSearchChanged: (value) {
                      setState(() {
                        _search = value;
                      });
                    },
                    onGradeChanged: (value) {
                      setState(() {
                        _selectedGrade = value;
                      });
                    },
                    onRefresh: _refreshHistory,
                    onClassify: _openClassify,
                    onDetails: _openDetails,
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
            title: const Text('History', style: AppTypography.cardTitle),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refreshHistory,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: _HistoryBody(
            search: _search,
            selectedGrade: _selectedGrade,
            onSearchChanged: (value) {
              setState(() {
                _search = value;
              });
            },
            onGradeChanged: (value) {
              setState(() {
                _selectedGrade = value;
              });
            },
            onRefresh: _refreshHistory,
            onClassify: _openClassify,
            onDetails: _openDetails,
            compact: true,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 1,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded),
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
                  _returnDashboard();
                  break;

                case 1:
                  break;

                case 2:
                  _openReports();
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

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({
    required this.search,
    required this.selectedGrade,
    required this.onSearchChanged,
    required this.onGradeChanged,
    required this.onRefresh,
    required this.onClassify,
    required this.onDetails,
    this.compact = false,
  });

  final String search;
  final String selectedGrade;

  final ValueChanged<String> onSearchChanged;

  final ValueChanged<String> onGradeChanged;

  final Future<void> Function() onRefresh;

  final Future<void> Function() onClassify;

  final Future<void> Function(ClassificationRecordModel record) onDetails;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    final records = [...history.records]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final grades =
        records
            .map((record) => record.predictedGrade.trim())
            .where((grade) => grade.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final validSelectedGrade =
        selectedGrade == 'All' || grades.contains(selectedGrade)
        ? selectedGrade
        : 'All';

    final query = search.trim().toLowerCase();

    final filteredRecords = records.where((record) {
      final matchesSearch =
          query.isEmpty ||
          record.predictedGrade.toLowerCase().contains(query) ||
          record.id.toLowerCase().contains(query);

      final matchesGrade =
          validSelectedGrade == 'All' ||
          record.predictedGrade.trim() == validSelectedGrade;

      return matchesSearch && matchesGrade;
    }).toList();

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
                if (!compact)
                  _DesktopHeader(total: records.length, onClassify: onClassify),

                if (!compact) const SizedBox(height: 20),

                if (compact) _MobileSummary(total: records.length),

                if (compact) const SizedBox(height: 14),

                _SearchBar(onChanged: onSearchChanged),

                if (grades.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _GradeFilters(
                    grades: grades,
                    selectedGrade: validSelectedGrade,
                    onSelected: onGradeChanged,
                  ),
                ],

                const SizedBox(height: 18),

                if (history.isLoading && records.isEmpty)
                  const _LoadingState()
                else if (history.error != null && records.isEmpty)
                  _ErrorState(message: history.error!, onRetry: onRefresh)
                else if (records.isEmpty)
                  _EmptyState(onClassify: onClassify)
                else if (filteredRecords.isEmpty)
                  const _NoResultsState()
                else if (compact)
                  _MobileHistoryList(
                    records: filteredRecords,
                    deletingIds: history.deletingIds,
                    onDetails: onDetails,
                  )
                else
                  _DesktopHistoryTable(
                    records: filteredRecords,
                    deletingIds: history.deletingIds,
                    onDetails: onDetails,
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
// DESKTOP HEADER
// ============================================================

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.total, required this.onClassify});

  final int total;

  final Future<void> Function() onClassify;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CLASSIFICATION HISTORY',
                style: AppTypography.label.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analysis History',
                style: AppTypography.pageTitle.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 7),
              Text(
                total == 1
                    ? '1 saved classification record.'
                    : '$total saved classification records.',
                style: AppTypography.bodySecondary,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
            ),
            onPressed: onClassify,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('New Analysis'),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// MOBILE SUMMARY
// ============================================================

class _MobileSummary extends StatelessWidget {
  const _MobileSummary({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.fiberBeige.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.fiberBeige,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Analyses',
                  style: AppTypography.cardTitle.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  total == 1
                      ? '1 saved classification'
                      : '$total saved classifications',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
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
// SEARCH
// ============================================================

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search analysis or grade...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: const Icon(Icons.tune_rounded, size: 19),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

// ============================================================
// FILTERS
// ============================================================

class _GradeFilters extends StatelessWidget {
  const _GradeFilters({
    required this.grades,
    required this.selectedGrade,
    required this.onSelected,
  });

  final List<String> grades;
  final String selectedGrade;

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = ['All', ...grades];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = options[index];

          final selected = value == selectedGrade;

          return ChoiceChip(
            label: Text(value),
            selected: selected,
            onSelected: (_) {
              onSelected(value);
            },
            showCheckmark: false,
            selectedColor: AppColors.primaryDark,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected ? AppColors.primaryDark : AppColors.border,
            ),
            labelStyle: AppTypography.caption.copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// MOBILE LIST
// ============================================================

class _MobileHistoryList extends StatelessWidget {
  const _MobileHistoryList({
    required this.records,
    required this.deletingIds,
    required this.onDetails,
  });

  final List<ClassificationRecordModel> records;

  final Set<String> deletingIds;

  final Future<void> Function(ClassificationRecordModel record) onDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < records.length; index++) ...[
          _MobileHistoryCard(
            record: records[index],
            deleting: deletingIds.contains(records[index].id),
            onDetails: onDetails,
          ),
          if (index < records.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MobileHistoryCard extends StatelessWidget {
  const _MobileHistoryCard({
    required this.record,
    required this.deleting,
    required this.onDetails,
  });

  final ClassificationRecordModel record;

  final bool deleting;

  final Future<void> Function(ClassificationRecordModel record) onDetails;

  @override
  Widget build(BuildContext context) {
    final confidence = _confidence(record.confidencePercentage);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: deleting
            ? null
            : () {
                onDetails(record);
              },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _RecordImage(record: record, width: 66, height: 66),

              const SizedBox(width: 12),

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

                    const SizedBox(height: 4),

                    Text(
                      _formatDateTime(record.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(fontSize: 9),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        _GradeChip(grade: record.predictedGrade),

                        const SizedBox(width: 8),

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
              ),

              const SizedBox(width: 8),

              if (deleting)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
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
// DESKTOP TABLE
// ============================================================

class _DesktopHistoryTable extends StatelessWidget {
  const _DesktopHistoryTable({
    required this.records,
    required this.deletingIds,
    required this.onDetails,
  });

  final List<ClassificationRecordModel> records;

  final Set<String> deletingIds;

  final Future<void> Function(ClassificationRecordModel record) onDetails;

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
        children: [
          const _TableHeader(),

          for (var index = 0; index < records.length; index++) ...[
            _DesktopRecordRow(
              record: records[index],
              deleting: deletingIds.contains(records[index].id),
              onDetails: onDetails,
            ),

            if (index < records.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      color: AppColors.surfaceMuted,
      child: const Row(
        children: [
          SizedBox(width: 76, child: Text('IMAGE', style: _tableHeaderStyle)),
          Expanded(flex: 3, child: Text('ANALYSIS', style: _tableHeaderStyle)),
          Expanded(flex: 2, child: Text('GRADE', style: _tableHeaderStyle)),
          Expanded(
            flex: 2,
            child: Text('CONFIDENCE', style: _tableHeaderStyle),
          ),
          Expanded(flex: 3, child: Text('DATE', style: _tableHeaderStyle)),
          SizedBox(
            width: 110,
            child: Text(
              'ACTION',
              textAlign: TextAlign.right,
              style: _tableHeaderStyle,
            ),
          ),
        ],
      ),
    );
  }
}

const _tableHeaderStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.8,
);

class _DesktopRecordRow extends StatelessWidget {
  const _DesktopRecordRow({
    required this.record,
    required this.deleting,
    required this.onDetails,
  });

  final ClassificationRecordModel record;

  final bool deleting;

  final Future<void> Function(ClassificationRecordModel record) onDetails;

  @override
  Widget build(BuildContext context) {
    final confidence = _confidence(record.confidencePercentage);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: deleting
            ? null
            : () {
                onDetails(record);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _RecordImage(record: record, width: 54, height: 44),
                ),
              ),

              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis ${_shortId(record.id)}',
                      style: AppTypography.cardTitle.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      record.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),

              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _GradeChip(grade: record.predictedGrade),
                ),
              ),

              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: confidence / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceSage,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      '${confidence.toStringAsFixed(0)}%',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                flex: 3,
                child: Text(
                  _formatDateTime(record.createdAt),
                  style: AppTypography.caption,
                ),
              ),

              SizedBox(
                width: 110,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: deleting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: () {
                            onDetails(record);
                          },
                          child: const Text('View Details'),
                        ),
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
// IMAGE
// ============================================================

class _RecordImage extends StatelessWidget {
  const _RecordImage({
    required this.record,
    required this.width,
    required this.height,
  });

  final ClassificationRecordModel record;

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(record.imageUrl);

    final token = context.read<AuthProvider>().token;

    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        width: width,
        height: height,
        child: imageUrl == null
            ? _FallbackImage(width: width, height: height)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                headers: token == null || token.trim().isEmpty
                    ? null
                    : {'Authorization': 'Bearer ${token.trim()}'},
                errorBuilder: (context, error, stackTrace) {
                  return _FallbackImage(width: width, height: height);
                },
              ),
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/abakascan_auth_hero.png',
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }
}

// ============================================================
// GRADE
// ============================================================

class _GradeChip extends StatelessWidget {
  const _GradeChip({required this.grade});

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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
// EMPTY
// ============================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClassify});

  final Future<void> Function() onClassify;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
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
              Icons.history_rounded,
              size: 30,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No analyses yet',
            style: AppTypography.sectionTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 7),
          const Text(
            'Your saved fiber classification results will appear here.',
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

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 34,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 12),
          Text('No matching analyses found.', style: AppTypography.cardTitle),
        ],
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
          SizedBox(height: 15),
          Text('Loading history...', style: AppTypography.bodySecondary),
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
          const SizedBox(height: 12),
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
// DESKTOP SIDEBAR
// ============================================================

class _HistorySidebar extends StatelessWidget {
  const _HistorySidebar({
    required this.onDashboard,
    required this.onClassify,
    required this.onSamples,
    required this.onReports,
    required this.onSettings,
    required this.onAbout,
    required this.onLogout,
  });

  final VoidCallback onDashboard;

  final Future<void> Function() onClassify;

  final Future<void> Function() onSamples;

  final Future<void> Function() onReports;

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

          const _SidebarItem(
            icon: Icons.history_rounded,
            label: 'History',
            selected: true,
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

String? _resolveImageUrl(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final trimmed = value.trim();

  final uri = Uri.tryParse(trimmed);

  if (uri != null && uri.hasScheme) {
    return trimmed;
  }

  var base = ApiConfig.baseUrl;

  if (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }

  final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';

  return '$base$path';
}
