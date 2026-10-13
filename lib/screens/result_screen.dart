import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../providers/app_providers.dart';

import 'classify_screen.dart';
import 'history_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.imageBytes,
    required this.predictedGrade,
    required this.confidence,
    this.classificationId,
    this.createdAt,
    this.savedToHistory = false,
  });

  final Uint8List imageBytes;
  final String predictedGrade;
  final double confidence;

  final String? classificationId;
  final DateTime? createdAt;

  final bool savedToHistory;

  double get confidencePercentage {
    if (confidence <= 1) {
      return (confidence * 100).clamp(0.0, 100.0).toDouble();
    }

    return confidence.clamp(0.0, 100.0).toDouble();
  }

  Future<void> _analyzeAnother(BuildContext context) async {
    context.read<ImageSelectionProvider>().removeImage();

    context.read<ClassificationProvider>().reset();

    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    await navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const ClassifyScreen()),
    );
  }

  Future<void> _openHistory(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  void _returnDashboard(BuildContext context) {
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
                  child: _ResultSidebar(
                    onDashboard: () {
                      _returnDashboard(context);
                    },
                    onAnalyzeAnother: () {
                      _analyzeAnother(context);
                    },
                    onHistory: () {
                      _openHistory(context);
                    },
                  ),
                ),
                Expanded(
                  child: _ResultBody(
                    imageBytes: imageBytes,
                    predictedGrade: predictedGrade,
                    confidence: confidencePercentage,
                    classificationId: classificationId,
                    createdAt: createdAt,
                    savedToHistory: savedToHistory,
                    onAnalyzeAnother: () {
                      return _analyzeAnother(context);
                    },
                    onHistory: () {
                      return _openHistory(context);
                    },
                    onDashboard: () {
                      _returnDashboard(context);
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
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text(
              'Analysis Result',
              style: AppTypography.cardTitle,
            ),
            actions: [
              PopupMenuButton<_ResultMenuAction>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (action) {
                  switch (action) {
                    case _ResultMenuAction.history:
                      _openHistory(context);
                      break;

                    case _ResultMenuAction.dashboard:
                      _returnDashboard(context);
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _ResultMenuAction.history,
                    child: Text('View History'),
                  ),
                  PopupMenuItem(
                    value: _ResultMenuAction.dashboard,
                    child: Text('Dashboard'),
                  ),
                ],
              ),
            ],
          ),
          body: _ResultBody(
            imageBytes: imageBytes,
            predictedGrade: predictedGrade,
            confidence: confidencePercentage,
            classificationId: classificationId,
            createdAt: createdAt,
            savedToHistory: savedToHistory,
            onAnalyzeAnother: () {
              return _analyzeAnother(context);
            },
            onHistory: () {
              return _openHistory(context);
            },
            onDashboard: () {
              _returnDashboard(context);
            },
            compact: true,
          ),
        );
      },
    );
  }
}

enum _ResultMenuAction { history, dashboard }

// ============================================================
// BODY
// ============================================================

class _ResultBody extends StatelessWidget {
  const _ResultBody({
    required this.imageBytes,
    required this.predictedGrade,
    required this.confidence,
    required this.classificationId,
    required this.createdAt,
    required this.savedToHistory,
    required this.onAnalyzeAnother,
    required this.onHistory,
    required this.onDashboard,
    this.compact = false,
  });

  final Uint8List imageBytes;

  final String predictedGrade;
  final double confidence;

  final String? classificationId;
  final DateTime? createdAt;

  final bool savedToHistory;

  final Future<void> Function() onAnalyzeAnother;

  final Future<void> Function() onHistory;

  final VoidCallback onDashboard;

  final bool compact;

  @override
  Widget build(BuildContext context) {
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
              if (!compact) const _DesktopHeader(),

              if (!compact) const SizedBox(height: 22),

              if (compact)
                _MobileResultHeader(
                  classificationId: classificationId,
                  createdAt: createdAt,
                  savedToHistory: savedToHistory,
                ),

              if (compact) const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = compact || constraints.maxWidth < 860;

                  final image = _ResultImage(imageBytes: imageBytes);

                  final result = _ClassificationCard(
                    predictedGrade: predictedGrade,
                    confidence: confidence,
                    classificationId: classificationId,
                    createdAt: createdAt,
                    savedToHistory: savedToHistory,
                  );

                  if (stacked) {
                    return Column(
                      children: [image, const SizedBox(height: 14), result],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: image),
                      const SizedBox(width: 18),
                      Expanded(flex: 5, child: result),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),

              _ResultActions(
                compact: compact,
                onAnalyzeAnother: onAnalyzeAnother,
                onHistory: onHistory,
                onDashboard: onDashboard,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CLASSIFICATION RESULT',
                style: AppTypography.label.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analysis Complete',
                style: AppTypography.pageTitle.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 8),
              Text(
                'Review the predicted fiber grade and classification confidence.',
                style: AppTypography.bodySecondary.copyWith(height: 1.55),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                'Analysis complete',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
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
// MOBILE HEADER
// ============================================================

class _MobileResultHeader extends StatelessWidget {
  const _MobileResultHeader({
    required this.classificationId,
    required this.createdAt,
    required this.savedToHistory,
  });

  final String? classificationId;
  final DateTime? createdAt;
  final bool savedToHistory;

  @override
  Widget build(BuildContext context) {
    final id = _displayId(classificationId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                id == null ? 'Classification Result' : 'Analysis $id',
                style: AppTypography.cardTitle.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                createdAt == null
                    ? 'Analysis complete'
                    : _formatDateTime(createdAt!),
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        if (savedToHistory)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Saved',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
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
// RESULT IMAGE
// ============================================================

class _ResultImage extends StatelessWidget {
  const _ResultImage({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
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
            child: Container(
              color: AppColors.surfaceMuted,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
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
                        'Image used for this classification',
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

// ============================================================
// CLASSIFICATION CARD
// ============================================================

class _ClassificationCard extends StatelessWidget {
  const _ClassificationCard({
    required this.predictedGrade,
    required this.confidence,
    required this.classificationId,
    required this.createdAt,
    required this.savedToHistory,
  });

  final String predictedGrade;
  final double confidence;

  final String? classificationId;
  final DateTime? createdAt;

  final bool savedToHistory;

  @override
  Widget build(BuildContext context) {
    final safeConfidence = confidence.clamp(0.0, 100.0).toDouble();

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
            'CLASSIFICATION RESULT',
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
                  constraints: const BoxConstraints(minHeight: 150),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PREDICTED GRADE',
                        style: AppTypography.label.copyWith(
                          color: AppColors.primary,
                          fontSize: 8,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        predictedGrade,
                        style: AppTypography.pageTitle.copyWith(
                          color: AppColors.primaryDark,
                          fontSize: 31,
                          height: 1.02,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              _ConfidenceCircle(confidence: safeConfidence),
            ],
          ),

          const SizedBox(height: 22),

          Text(
            'Analysis Details',
            style: AppTypography.cardTitle.copyWith(fontSize: 15),
          ),

          const SizedBox(height: 12),

          _DetailRow(label: 'Predicted Grade', value: predictedGrade),

          const Divider(height: 23),

          _DetailRow(
            label: 'Confidence',
            value: '${safeConfidence.toStringAsFixed(1)}%',
          ),

          if (createdAt != null) ...[
            const Divider(height: 23),
            _DetailRow(
              label: 'Classification Date',
              value: _formatDateTime(createdAt!),
            ),
          ],

          if (classificationId != null &&
              classificationId!.trim().isNotEmpty) ...[
            const Divider(height: 23),
            _DetailRow(
              label: 'Classification ID',
              value: classificationId!,
              selectable: true,
            ),
          ],

          const Divider(height: 23),

          _DetailRow(
            label: 'History',
            value: savedToHistory
                ? 'Saved to classification history'
                : 'Save status not confirmed',
          ),

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
                  Icons.analytics_outlined,
                  size: 19,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'This result was produced from the submitted image using the ABAKASCAN classification model.',
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
// CONFIDENCE CIRCLE
// ============================================================

class _ConfidenceCircle extends StatelessWidget {
  const _ConfidenceCircle({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 104,
            height: 104,
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
                  fontSize: 23,
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

// ============================================================
// DETAIL ROW
// ============================================================

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

class _ResultActions extends StatelessWidget {
  const _ResultActions({
    required this.compact,
    required this.onAnalyzeAnother,
    required this.onHistory,
    required this.onDashboard,
  });

  final bool compact;

  final Future<void> Function() onAnalyzeAnother;

  final Future<void> Function() onHistory;

  final VoidCallback onDashboard;

  @override
  Widget build(BuildContext context) {
    final analyzeButton = SizedBox(
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
        onPressed: onAnalyzeAnother,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Analyze Another Image'),
      ),
    );

    final historyButton = SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onHistory,
        icon: const Icon(Icons.history_rounded),
        label: const Text('View History'),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [analyzeButton, const SizedBox(height: 10), historyButton],
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
        children: [
          TextButton.icon(
            onPressed: onDashboard,
            icon: const Icon(Icons.dashboard_outlined),
            label: const Text('Dashboard'),
          ),
          const Spacer(),
          historyButton,
          const SizedBox(width: 10),
          analyzeButton,
        ],
      ),
    );
  }
}

// ============================================================
// DESKTOP SIDEBAR
// ============================================================

class _ResultSidebar extends StatelessWidget {
  const _ResultSidebar({
    required this.onDashboard,
    required this.onAnalyzeAnother,
    required this.onHistory,
  });

  final VoidCallback onDashboard;
  final VoidCallback onAnalyzeAnother;
  final VoidCallback onHistory;

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
            onTap: onAnalyzeAnother,
          ),

          _SidebarItem(
            icon: Icons.history_rounded,
            label: 'History',
            onTap: onHistory,
          ),

          const _SidebarItem(
            icon: Icons.analytics_outlined,
            label: 'Result',
            selected: true,
          ),

          const Spacer(),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 128,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/abakascan_auth_hero.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: AppColors.primaryDark.withValues(alpha: 0.42),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'FIBER\nINTELLIGENCE',
                        style: AppTypography.label.copyWith(
                          color: AppColors.fiberBeige,
                          fontSize: 9,
                          height: 1.4,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

String? _displayId(String? rawId) {
  if (rawId == null || rawId.trim().isEmpty) {
    return null;
  }

  final id = rawId.trim();

  if (id.length <= 8) {
    return id;
  }

  return id.substring(0, 8);
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
