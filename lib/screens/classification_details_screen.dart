import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../services/api_services.dart';

import 'about_screen.dart';
import 'classify_screen.dart';
import 'reports_screen.dart';
import 'samples_screen.dart';
import 'settings_screen.dart';

class ClassificationDetailsScreen extends StatefulWidget {
  const ClassificationDetailsScreen({
    super.key,
    required this.record,
    required this.onDelete,
  });

  final ClassificationRecordModel record;

  final Future<bool> Function(ClassificationRecordModel record) onDelete;

  @override
  State<ClassificationDetailsScreen> createState() =>
      _ClassificationDetailsScreenState();
}

class _ClassificationDetailsScreenState
    extends State<ClassificationDetailsScreen> {
  bool _deleting = false;

  void _backToHistory() {
    if (_deleting) {
      return;
    }

    Navigator.pop(context, false);
  }

  Future<void> _deleteRecord() async {
    if (_deleting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ),
          title: const Text('Delete Classification?'),
          content: const Text(
            'This classification record will be permanently removed '
            'from your history. This action cannot be undone.',
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
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Record'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _deleting = true;
    });

    final deleted = await widget.onDelete(widget.record);

    if (!mounted) {
      return;
    }

    if (deleted) {
      Navigator.pop(context, true);

      return;
    }

    setState(() {
      _deleting = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete the classification record. Please try again.',
          ),
        ),
      );
  }

  Future<void> _openClassify() async {
    if (_deleting) {
      return;
    }

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ClassifyScreen()));
  }

  Future<void> _openSamples() async {
    if (_deleting) {
      return;
    }

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SamplesScreen()));
  }

  Future<void> _openReports() async {
    if (_deleting) {
      return;
    }

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
  }

  Future<void> _openSettings() async {
    if (_deleting) {
      return;
    }

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _openAbout() async {
    if (_deleting) {
      return;
    }

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AboutScreen()));
  }

  void _returnToDashboard() {
    if (_deleting) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _logout() async {
    if (_deleting) {
      return;
    }

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
                  child: _DetailsSidebar(
                    onDashboard: _returnToDashboard,
                    onClassify: _openClassify,
                    onHistory: _backToHistory,
                    onSamples: _openSamples,
                    onReports: _openReports,
                    onSettings: _openSettings,
                    onAbout: _openAbout,
                    onLogout: _logout,
                    disabled: _deleting,
                  ),
                ),
                Expanded(
                  child: _DetailsBody(
                    record: widget.record,
                    deleting: _deleting,
                    onBack: _backToHistory,
                    onDelete: _deleteRecord,
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
              tooltip: 'Back to History',
              onPressed: _deleting ? null : _backToHistory,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text(
              'Analysis Details',
              style: AppTypography.cardTitle,
            ),
            actions: [
              PopupMenuButton<_DetailsMenuAction>(
                enabled: !_deleting,
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (action) {
                  switch (action) {
                    case _DetailsMenuAction.delete:
                      _deleteRecord();
                      break;

                    case _DetailsMenuAction.dashboard:
                      _returnToDashboard();
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _DetailsMenuAction.dashboard,
                    child: Text('Dashboard'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _DetailsMenuAction.delete,
                    child: Text('Delete Record'),
                  ),
                ],
              ),
            ],
          ),
          body: _DetailsBody(
            record: widget.record,
            deleting: _deleting,
            onBack: _backToHistory,
            onDelete: _deleteRecord,
            compact: true,
          ),
        );
      },
    );
  }
}

enum _DetailsMenuAction { dashboard, delete }

// ============================================================
// BODY
// ============================================================

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.record,
    required this.deleting,
    required this.onBack,
    required this.onDelete,
    this.compact = false,
  });

  final ClassificationRecordModel record;

  final bool deleting;

  final VoidCallback onBack;

  final Future<void> Function() onDelete;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token;

    return SingleChildScrollView(
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
              if (!compact) _DesktopHeader(record: record, onBack: onBack),

              if (!compact) const SizedBox(height: 22),

              if (compact) _MobileRecordHeader(record: record),

              if (compact) const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = compact || constraints.maxWidth < 860;

                  final image = _StoredImagePanel(
                    imageUrl: record.imageUrl,
                    token: token,
                  );

                  final information = _ClassificationInformation(
                    record: record,
                  );

                  if (stacked) {
                    return Column(
                      children: [
                        image,
                        const SizedBox(height: 14),
                        information,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: image),
                      const SizedBox(width: 18),
                      Expanded(flex: 5, child: information),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),

              _RecordActions(
                deleting: deleting,
                onBack: onBack,
                onDelete: onDelete,
                compact: compact,
              ),
            ],
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
  const _DesktopHeader({required this.record, required this.onBack});

  final ClassificationRecordModel record;

  final VoidCallback onBack;

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
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analysis Details',
                style: AppTypography.pageTitle.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 7),
              Text(
                'Review the saved image and classification information for Analysis ${_shortId(record.id)}.',
                style: AppTypography.bodySecondary.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Back to History'),
        ),
      ],
    );
  }
}

class _MobileRecordHeader extends StatelessWidget {
  const _MobileRecordHeader({required this.record});

  final ClassificationRecordModel record;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis ${_shortId(record.id)}',
                style: AppTypography.cardTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(record.createdAt),
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        _GradeChip(grade: record.predictedGrade),
      ],
    );
  }
}

// ============================================================
// IMAGE PANEL
// ============================================================

class _StoredImagePanel extends StatelessWidget {
  const _StoredImagePanel({required this.imageUrl, required this.token});

  final String? imageUrl;
  final String? token;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveImageUrl(imageUrl);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: resolvedUrl == null
                ? const _ImageFallback(unavailable: false)
                : Image.network(
                    resolvedUrl,
                    fit: BoxFit.cover,
                    headers: token == null || token!.trim().isEmpty
                        ? null
                        : {'Authorization': 'Bearer ${token!.trim()}'},
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }

                      return const _ImageLoading();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const _ImageFallback(unavailable: true);
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submitted Fiber Image',
                        style: AppTypography.cardTitle,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Stored image associated with this analysis',
                        style: AppTypography.caption,
                      ),
                    ],
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

class _ImageLoading extends StatelessWidget {
  const _ImageLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: 12),
          Text('Loading image...', style: AppTypography.bodySecondary),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.unavailable});

  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/abakascan_auth_hero.png', fit: BoxFit.cover),
        Container(color: AppColors.primaryDark.withValues(alpha: 0.76)),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _FiberLinePainter()),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  unavailable
                      ? Icons.broken_image_outlined
                      : Icons.image_not_supported_outlined,
                  color: AppColors.fiberBeige,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  unavailable
                      ? 'Stored image unavailable'
                      : 'No stored image available',
                  textAlign: TextAlign.center,
                  style: AppTypography.cardTitle.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(
                  unavailable
                      ? 'The image associated with this record could not be displayed.'
                      : 'This classification record does not include an accessible stored image.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// INFORMATION
// ============================================================

class _ClassificationInformation extends StatelessWidget {
  const _ClassificationInformation({required this.record});

  final ClassificationRecordModel record;

  @override
  Widget build(BuildContext context) {
    final confidence = record.confidencePercentage.clamp(0.0, 100.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAVED CLASSIFICATION',
            style: AppTypography.label.copyWith(
              color: AppColors.primary,
              fontSize: 9,
              letterSpacing: 1.7,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 145),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREDICTED GRADE',
                        style: AppTypography.label.copyWith(
                          color: AppColors.primary,
                          fontSize: 8,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        record.predictedGrade,
                        style: AppTypography.pageTitle.copyWith(
                          color: AppColors.primaryDark,
                          fontSize: 30,
                          height: 1.02,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 15),

              _ConfidenceCircle(confidence: confidence),
            ],
          ),

          const SizedBox(height: 22),

          Text(
            'Analysis Information',
            style: AppTypography.cardTitle.copyWith(fontSize: 15),
          ),

          const SizedBox(height: 12),

          _DetailRow(label: 'Predicted Grade', value: record.predictedGrade),

          const Divider(height: 23),

          _DetailRow(
            label: 'Confidence',
            value: '${confidence.toStringAsFixed(1)}%',
          ),

          const Divider(height: 23),

          _DetailRow(
            label: 'Classification Date',
            value: _formatDateTime(record.createdAt),
          ),

          const Divider(height: 23),

          _DetailRow(
            label: 'Classification ID',
            value: record.id,
            selectable: true,
          ),

          if (record.modelName != null &&
              record.modelName!.trim().isNotEmpty) ...[
            const Divider(height: 23),
            _DetailRow(label: 'Model', value: record.modelName!),
          ],

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.history_outlined,
                  size: 19,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'This is a saved classification record from your analysis history.',
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

class _ConfidenceCircle extends StatelessWidget {
  const _ConfidenceCircle({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: confidence / 100,
              strokeWidth: 9,
              backgroundColor: AppColors.surfaceSage,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${confidence.toStringAsFixed(0)}%',
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Confidence',
                style: AppTypography.caption.copyWith(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;

  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final valueWidget = selectable
        ? SelectableText(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          )
        : Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: AppTypography.bodySecondary),
        ),
        const SizedBox(width: 14),
        Expanded(flex: 6, child: valueWidget),
      ],
    );
  }
}

// ============================================================
// ACTIONS
// ============================================================

class _RecordActions extends StatelessWidget {
  const _RecordActions({
    required this.deleting,
    required this.onBack,
    required this.onDelete,
    required this.compact,
  });

  final bool deleting;

  final VoidCallback onBack;

  final Future<void> Function() onDelete;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final backButton = SizedBox(
      height: 51,
      child: OutlinedButton.icon(
        onPressed: deleting ? null : onBack,
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('Back to History'),
      ),
    );

    final deleteButton = SizedBox(
      height: 51,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
        ),
        onPressed: deleting ? null : onDelete,
        icon: deleting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.delete_outline),
        label: Text(deleting ? 'Deleting...' : 'Delete Record'),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [backButton, const SizedBox(height: 10), deleteButton],
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
      child: Row(children: [backButton, const Spacer(), deleteButton]),
    );
  }
}

// ============================================================
// SIDEBAR
// ============================================================

class _DetailsSidebar extends StatelessWidget {
  const _DetailsSidebar({
    required this.onDashboard,
    required this.onClassify,
    required this.onHistory,
    required this.onSamples,
    required this.onReports,
    required this.onSettings,
    required this.onAbout,
    required this.onLogout,
    required this.disabled,
  });

  final VoidCallback onDashboard;
  final VoidCallback onHistory;

  final Future<void> Function() onClassify;

  final Future<void> Function() onSamples;

  final Future<void> Function() onReports;

  final Future<void> Function() onSettings;

  final Future<void> Function() onAbout;

  final Future<void> Function() onLogout;

  final bool disabled;

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
            onTap: disabled ? null : onDashboard,
          ),

          _SidebarItem(
            icon: Icons.camera_alt_outlined,
            label: 'Analyze',
            onTap: disabled ? null : onClassify,
          ),

          _SidebarItem(
            icon: Icons.history_rounded,
            label: 'History',
            selected: true,
            onTap: disabled ? null : onHistory,
          ),

          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            label: 'Samples',
            onTap: disabled ? null : onSamples,
          ),

          _SidebarItem(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            onTap: disabled ? null : onReports,
          ),

          _SidebarItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: disabled ? null : onSettings,
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
            onTap: disabled ? null : onAbout,
          ),

          _SidebarItem(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            onTap: disabled ? null : onLogout,
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
        : onTap == null
        ? Colors.white.withValues(alpha: 0.34)
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
// GRADE CHIP
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
// DECORATIVE FIBER LINES
// ============================================================

class _FiberLinePainter extends CustomPainter {
  const _FiberLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < 9; index++) {
      final y = size.height * (0.37 + index * 0.028);

      final path = Path()
        ..moveTo(-20, y)
        ..cubicTo(
          size.width * 0.25,
          y + 45,
          size.width * 0.67,
          y - 36,
          size.width + 30,
          y + 8,
        );

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = index % 3 == 0 ? 1.1 : 0.7
          ..color = AppColors.fiberBeige.withValues(alpha: 0.32),
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
