import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app/theme.dart';

// Result content belongs to ClassifyScreen. It owns no route, sidebar or Scaffold.

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.imageBytes,
    required this.predictedGrade,
    required this.confidence,
    required this.onAnalyzeAnother,
    required this.onHistory,
    required this.onDashboard,
    this.gradeScores,
    this.classificationId,
    this.createdAt,
    this.savedToHistory = false,
    this.detectionStatus = 'graded',
    this.detectionMessage,
  });
  final Uint8List imageBytes;
  final String predictedGrade;
  final double confidence;
  final Map<String, double>? gradeScores;
  final String? classificationId;
  final DateTime? createdAt;
  final bool savedToHistory;
  final String detectionStatus;
  final String? detectionMessage;
  final Future<void> Function() onAnalyzeAnother;
  final Future<void> Function() onHistory;
  final VoidCallback onDashboard;
  double get confidencePercentage {
    if (confidence <= 1) {
      return (confidence * 100).clamp(0.0, 100.0).toDouble();
    }
    return confidence.clamp(0.0, 100.0).toDouble();
  }

  Widget _buildNonGradedResult(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final multiple = detectionStatus == 'multiple_bundles';
    final uncertain = detectionStatus == 'uncertain_grade';
    final title = uncertain
        ? 'Uncertain grade'
        : multiple
        ? 'Multiple bundles detected'
        : 'Unidentified object';
    final message =
        detectionMessage ??
        (uncertain
            ? 'The recognition check passed, but the model could not determine '
                  'a JK, S-I, or S-S2 grade confidently. No grade was assigned or saved.'
            : multiple
            ? 'Please capture one clearly separated bundle and try again.'
            : 'Material was not identified with sufficient confidence. '
                  'Please upload a clear close-up section of one abaca bundle.');
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              title,
              style: AppTypography.pageTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTypography.body.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _ResultImage(imageBytes: imageBytes),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  _DetailRow(label: 'Grade', value: 'Not assigned'),
                  Divider(height: 24),
                  _DetailRow(label: 'Classification confidence', value: 'N/A'),
                  Divider(height: 24),
                  _DetailRow(label: 'History', value: 'Not saved'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAnalyzeAnother,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Retake or Upload Another Image'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (detectionStatus == 'unidentified_object' ||
        detectionStatus == 'multiple_bundles' ||
        detectionStatus == 'uncertain_grade') {
      return _buildNonGradedResult(context);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return _ResultBody(
          imageBytes: imageBytes,
          predictedGrade: predictedGrade,
          confidence: confidencePercentage,
          gradeScores: gradeScores,
          classificationId: classificationId,
          createdAt: createdAt,
          savedToHistory: savedToHistory,
          onAnalyzeAnother: onAnalyzeAnother,
          onHistory: onHistory,
          onDashboard: onDashboard,
          compact: constraints.maxWidth < 860,
        );
      },
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({
    required this.imageBytes,
    required this.predictedGrade,
    required this.confidence,
    required this.gradeScores,
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
  final Map<String, double>? gradeScores;
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
                    gradeScores: gradeScores,
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
    final colors = Theme.of(context).colorScheme;
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
                  color: colors.primary,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analysis Complete',
                style: AppTypography.pageTitle.copyWith(
                  color: colors.onSurface,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Review the classification result and the scores for all three grades.',
                style: AppTypography.bodySecondary.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 17,
                color: colors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                'Analysis complete',
                style: AppTypography.caption.copyWith(
                  color: colors.onPrimaryContainer,
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
    final colors = Theme.of(context).colorScheme;
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
                style: AppTypography.cardTitle.copyWith(
                  color: colors.onSurface,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                createdAt == null
                    ? 'Analysis complete'
                    : _formatDateTime(createdAt!),
                style: AppTypography.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (savedToHistory)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: colors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Saved',
                  style: AppTypography.caption.copyWith(
                    color: colors.onPrimaryContainer,
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
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              color: colors.surfaceContainerHighest,
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
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: colors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submitted Fiber Image',
                        style: AppTypography.cardTitle.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Image used for this classification',
                        style: AppTypography.caption.copyWith(
                          color: colors.onSurfaceVariant,
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
    required this.gradeScores,
    required this.classificationId,
    required this.createdAt,
    required this.savedToHistory,
  });
  final String predictedGrade;
  final double confidence;
  final Map<String, double>? gradeScores;
  final String? classificationId;
  final DateTime? createdAt;
  final bool savedToHistory;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final safeConfidence = confidence.clamp(0.0, 100.0).toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLASSIFICATION RESULT',
            style: AppTypography.label.copyWith(
              color: colors.primary,
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
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'GRADE',
                        style: AppTypography.label.copyWith(
                          color: colors.primary,
                          fontSize: 8,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        predictedGrade,
                        style: AppTypography.pageTitle.copyWith(
                          color: colors.onPrimaryContainer,
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
          _GradeScoreDistribution(
            gradeScores: gradeScores,
            predictedGrade: predictedGrade,
          ),
          const SizedBox(height: 22),
          Text(
            'Analysis Details',
            style: AppTypography.cardTitle.copyWith(
              color: colors.onSurface,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Grade', value: predictedGrade),
          const Divider(height: 23),
          _DetailRow(
            label: 'Top grade score',
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
        ],
      ),
    );
  }
}

// ============================================================
// GRADE MODEL SCORE DISTRIBUTION
// ============================================================

class _GradeScoreDistribution extends StatelessWidget {
  const _GradeScoreDistribution({
    required this.gradeScores,
    required this.predictedGrade,
  });

  final Map<String, double>? gradeScores;
  final String predictedGrade;
  static const _grades = ['JK', 'S-I', 'S-S2'];

  // Keep the backend's score distribution. Never infer missing grades
  // from the highest score or convert absent scores into zeros.
  bool get _hasValidScores {
    final scores = gradeScores;
    if (scores == null || scores.length != _grades.length) return false;

    var total = 0.0;
    var highest = 0.0;
    for (final grade in _grades) {
      final value = scores[grade];
      if (value == null || !value.isFinite || value < 0 || value > 1) {
        return false;
      }
      total += value;
      if (value > highest) highest = value;
    }
    final selected = scores[predictedGrade];
    return (total - 1.0).abs() <= 0.0001 &&
        selected != null &&
        (selected - highest).abs() <= 0.000001;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grade model scores',
          style: AppTypography.cardTitle.copyWith(
            color: colors.onSurface,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        if (!_hasValidScores)
          Text(
            'The three-grade score distribution is unavailable for this result.',
            style: AppTypography.bodySecondary.copyWith(
              color: colors.onSurfaceVariant,
            ),
          )
        else ...[
          for (final grade in _grades) ...[
            _GradeScoreBar(
              grade: grade,
              score: gradeScores![grade]!,
              isPredicted: grade == predictedGrade,
            ),
            if (grade != _grades.last) const SizedBox(height: 14),
          ],
        ],
      ],
    );
  }
}

class _GradeScoreBar extends StatelessWidget {
  const _GradeScoreBar({
    required this.grade,
    required this.score,
    required this.isPredicted,
  });

  final String grade;
  final double score;
  final bool isPredicted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final barColor = isPredicted ? colors.primary : colors.secondary;

    return Semantics(
      label: '$grade${isPredicted ? ", classification result" : ""}',
      value: '${(score * 100).toStringAsFixed(2)} percent',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isPredicted ? '$grade (classified)' : grade,
                    style: AppTypography.body.copyWith(
                      color: isPredicted ? colors.primary : colors.onSurface,
                      fontWeight: isPredicted
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(score * 100).toStringAsFixed(2)}%',
                  style: AppTypography.body.copyWith(
                    color: isPredicted ? colors.primary : colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: score,
                minHeight: 9,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ),
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
    final colors = Theme.of(context).colorScheme;
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
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${confidence.toStringAsFixed(0)}%',
                style: AppTypography.sectionTitle.copyWith(
                  color: colors.onSurface,
                  fontSize: 23,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Grade score',
                style: AppTypography.caption.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 8,
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
    final colors = Theme.of(context).colorScheme;
    final valueWidget = selectable
        ? SelectableText(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.body.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          )
        : Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.body.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: AppTypography.bodySecondary.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
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
    final colors = Theme.of(context).colorScheme;
    final analyzeButton = SizedBox(
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
        ),
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
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
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
