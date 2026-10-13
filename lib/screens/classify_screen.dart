import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../providers/app_providers.dart';

import 'about_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';
import 'result_screen.dart';
import 'samples_screen.dart';
import 'settings_screen.dart';

class ClassifyScreen extends StatefulWidget {
  const ClassifyScreen({super.key});

  @override
  State<ClassifyScreen> createState() => _ClassifyScreenState();
}

class _ClassifyScreenState extends State<ClassifyScreen> {
  Future<void> _chooseImage() async {
    final imageProvider = context.read<ImageSelectionProvider>();

    final classificationProvider = context.read<ClassificationProvider>();

    if (classificationProvider.isAnalyzing || imageProvider.loading) {
      return;
    }

    classificationProvider.reset();

    await imageProvider.chooseImage();
  }

  Future<void> _captureImage() async {
    final imageProvider = context.read<ImageSelectionProvider>();

    final classificationProvider = context.read<ClassificationProvider>();

    if (classificationProvider.isAnalyzing || imageProvider.loading) {
      return;
    }

    classificationProvider.reset();

    await imageProvider.captureImage();
  }

  Future<void> _removeImage() async {
    final classificationProvider = context.read<ClassificationProvider>();

    if (classificationProvider.isAnalyzing) {
      return;
    }

    classificationProvider.reset();

    context.read<ImageSelectionProvider>().removeImage();
  }

  Future<bool> _requestAuthentication() async {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isAuthenticated) {
      return true;
    }

    final action = await showDialog<_AuthenticationAction>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign In Required'),
          content: const Text(
            'An ABAKASCAN account is required before '
            'submitting an image for classification.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext, _AuthenticationAction.register);
              },
              child: const Text('Create Account'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, _AuthenticationAction.login);
              },
              child: const Text('Log In'),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null) {
      return false;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          startInRegisterMode: action == _AuthenticationAction.register,
        ),
      ),
    );

    if (!mounted) {
      return false;
    }

    return context.read<AuthProvider>().isAuthenticated;
  }

  Future<void> _analyzeImage() async {
    final imageProvider = context.read<ImageSelectionProvider>();

    final classificationProvider = context.read<ClassificationProvider>();

    if (classificationProvider.isAnalyzing) {
      return;
    }

    if (!imageProvider.hasImage || imageProvider.selectedImageBytes == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Select or capture an abaca fiber image first.'),
          ),
        );

      return;
    }

    var authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      final authenticated = await _requestAuthentication();

      if (!mounted || !authenticated) {
        return;
      }

      authProvider = context.read<AuthProvider>();
    }

    final token = authProvider.token;

    if (token == null || token.trim().isEmpty) {
      return;
    }

    final bytes = imageProvider.selectedImageBytes!;

    final fileName = imageProvider.fileName ?? 'abaca_fiber.jpg';

    final success = await classificationProvider.classify(
      token: token,
      imageBytes: bytes,
      fileName: fileName,
    );

    if (!mounted) {
      return;
    }

    if (classificationProvider.sessionExpired) {
      await _handleExpiredSession();
      return;
    }

    if (!success || classificationProvider.result == null) {
      return;
    }

    final result = classificationProvider.result!;

    await _syncHistory();

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          imageBytes: bytes,
          predictedGrade: result.predictedGrade,
          confidence: result.confidence,
          classificationId: result.classificationId,
          createdAt: result.createdAt,
          savedToHistory: result.savedToHistory,
        ),
      ),
    );
  }

  Future<void> _syncHistory() async {
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

  void _returnHome() {
    if (context.read<ClassificationProvider>().isAnalyzing) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openHistory() async {
    if (context.read<ClassificationProvider>().isAnalyzing) {
      return;
    }

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  Future<void> _openSamples() async {
    if (context.read<ClassificationProvider>().isAnalyzing) {
      return;
    }

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SamplesScreen()));
  }

  Future<void> _openReports() async {
    if (context.read<ClassificationProvider>().isAnalyzing) {
      return;
    }

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
  }

  Future<void> _openSettings() async {
    if (context.read<ClassificationProvider>().isAnalyzing) {
      return;
    }

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _openAbout() async {
    if (context.read<ClassificationProvider>().isAnalyzing) {
      return;
    }

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AboutScreen()));
  }

  Future<void> _logout() async {
    final classificationProvider = context.read<ClassificationProvider>();

    if (classificationProvider.isAnalyzing) {
      return;
    }

    context.read<ImageSelectionProvider>().removeImage();

    classificationProvider.reset();

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
    final authProvider = context.watch<AuthProvider>();

    final classificationProvider = context.watch<ClassificationProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= AppBreakpoints.desktop;

        if (desktop && authProvider.isAuthenticated && authProvider.isUser) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 214,
                      child: _AnalyzeSidebar(
                        onDashboard: _returnHome,
                        onHistory: _openHistory,
                        onSamples: _openSamples,
                        onReports: _openReports,
                        onSettings: _openSettings,
                        onAbout: _openAbout,
                        onLogout: _logout,
                        disabled: classificationProvider.isAnalyzing,
                      ),
                    ),
                    const Expanded(child: _AnalyzeBody()),
                  ],
                ),
                if (classificationProvider.isAnalyzing)
                  const _AnalysisOverlay(),
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
            leading: IconButton(
              tooltip: 'Back',
              onPressed: classificationProvider.isAnalyzing
                  ? null
                  : () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      } else {
                        _returnHome();
                      }
                    },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text('Analyze Fiber', style: AppTypography.cardTitle),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'About',
                onPressed: classificationProvider.isAnalyzing
                    ? null
                    : _openAbout,
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          body: Stack(
            children: [
              const _AnalyzeBody(compact: true),
              if (classificationProvider.isAnalyzing) const _AnalysisOverlay(),
            ],
          ),
        );
      },
    );
  }
}

enum _AuthenticationAction { login, register }

// ============================================================
// MAIN BODY
// ============================================================

class _AnalyzeBody extends StatelessWidget {
  const _AnalyzeBody({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageProvider = context.watch<ImageSelectionProvider>();

    final classificationProvider = context.watch<ClassificationProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 28,
        compact ? 8 : 26,
        compact ? 16 : 28,
        40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) const _DesktopPageHeader(),

              if (!compact) const SizedBox(height: 22),

              if (compact) const SizedBox(height: 18),

              if (!imageProvider.hasImage)
                _EmptyAnalyzePanel(compact: compact)
              else
                _SelectedAnalyzePanel(compact: compact),

              if (imageProvider.error != null) ...[
                const SizedBox(height: 14),
                _ImageErrorPanel(message: imageProvider.error!),
              ],

              if (classificationProvider.hasError &&
                  imageProvider.hasImage) ...[
                const SizedBox(height: 14),
                const _ClassificationError(),
              ],

              const SizedBox(height: 24),

              const _PhotoGuidelines(),

              const SizedBox(height: 30),
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

class _DesktopPageHeader extends StatelessWidget {
  const _DesktopPageHeader();

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
                'FIBER ANALYSIS',
                style: AppTypography.label.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analyze Abaca Fiber',
                style: AppTypography.pageTitle.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Text(
                  'Upload or capture a clear abaca fiber image, review it, then submit it for classification.',
                  style: AppTypography.bodySecondary.copyWith(height: 1.55),
                ),
              ),
            ],
          ),
        ),
        const _StepIndicator(),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _StepDot(number: '1', active: true),
          _StepLine(active: true),
          const _StepDot(number: '2'),
          _StepLine(),
          const _StepDot(number: '3'),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.number, this.active = false});

  final String number;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primaryDark : AppColors.surfaceMuted,
        border: Border.all(
          color: active ? AppColors.primaryDark : AppColors.border,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: AppTypography.caption.copyWith(
          color: active ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 2,
      color: active ? AppColors.primary : AppColors.border,
    );
  }
}

// ============================================================
// MOBILE INTRO
// ============================================================

// ============================================================
// EMPTY UPLOAD PANEL
// ============================================================

class _EmptyAnalyzePanel extends StatelessWidget {
  const _EmptyAnalyzePanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageProvider = context.watch<ImageSelectionProvider>();
    final state = context.findAncestorStateOfType<_ClassifyScreenState>();

    final uploadPanel = _UploadPanel(
      loading: imageProvider.loading,
      onChoose: state?._chooseImage,
      onCapture: state?._captureImage,
    );

    final overlap = compact ? 28.0 : 45.0;
    final horizontalPadding = compact ? 8.0 : 32.0;

    return Column(
      children: [
        const _AbacaVisualPanel(),

        Transform.translate(
          offset: Offset(0, -overlap),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: uploadPanel,
          ),
        ),
      ],
    );
  }
}

class _AbacaVisualPanel extends StatelessWidget {
  const _AbacaVisualPanel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 300,
      child: Container(
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xDB0F3D2E),
                    Color(0xA80F3D2E),
                    Color(0x280F3D2E),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Brand(),

                  const Spacer(),

                  Text(
                    'See the quality\nin every fiber.',
                    style: AppTypography.pageTitle.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.04,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '',
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

class _UploadPanel extends StatelessWidget {
  const _UploadPanel({
    required this.loading,
    required this.onChoose,
    required this.onCapture,
  });

  final bool loading;
  final VoidCallback? onChoose;
  final VoidCallback? onCapture;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 330),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.primaryDark,
              size: 35,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Add Fiber Image',
            textAlign: TextAlign.center,
            style: AppTypography.sectionTitle.copyWith(
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Upload a clear JPG, JPEG, or PNG image of the abaca fiber you want to classify.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary.copyWith(height: 1.55),
            ),
          ),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 30,
                  color: AppColors.textSecondary,
                ),

                const SizedBox(height: 10),

                Text(
                  kIsWeb
                      ? 'Choose an image from your device'
                      : 'Choose how you want to add your image',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 18),

                if (loading)
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else if (kIsWeb)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: onChoose,
                        icon: const Icon(Icons.upload_file_outlined, size: 20),
                        label: const Text(
                          'Upload Photo',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: onCapture,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text(
                              'Capture Photo',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: onChoose,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Choose from Gallery'),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),

                    const SizedBox(width: 7),

                    Text('JPG • JPEG • PNG', style: AppTypography.caption),
                  ],
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
// SELECTED IMAGE
// ============================================================

class _SelectedAnalyzePanel extends StatelessWidget {
  const _SelectedAnalyzePanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageProvider = context.watch<ImageSelectionProvider>();

    final classificationProvider = context.watch<ClassificationProvider>();

    final screenState = context.findAncestorStateOfType<_ClassifyScreenState>();

    final bytes = imageProvider.selectedImageBytes;

    final fromCamera = imageProvider.source == SelectedImageSource.mobileCamera;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = compact || constraints.maxWidth < 840;

          final preview = _ImagePreview(bytes: bytes);

          final controls = _ImageControls(
            fileName: imageProvider.fileName,
            fromCamera: fromCamera,
            analyzing: classificationProvider.isAnalyzing,
            onAnalyze: screenState?._analyzeImage,
            onChoose: screenState?._chooseImage,
            onCapture: screenState?._captureImage,
            onRemove: screenState?._removeImage,
          );

          if (stacked) {
            return Column(children: [preview, controls]);
          }

          return SizedBox(
            height: 480,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: preview),
                const VerticalDivider(width: 1),
                Expanded(flex: 4, child: controls),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.bytes});

  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      constraints: const BoxConstraints(minHeight: 300),
      child: bytes == null
          ? const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 46,
                color: AppColors.textSecondary,
              ),
            )
          : Image.memory(bytes!, fit: BoxFit.contain, gaplessPlayback: true),
    );
  }
}

class _ImageControls extends StatelessWidget {
  const _ImageControls({
    required this.fileName,
    required this.fromCamera,
    required this.analyzing,
    required this.onAnalyze,
    required this.onChoose,
    required this.onCapture,
    required this.onRemove,
  });

  final String? fileName;
  final bool fromCamera;
  final bool analyzing;

  final VoidCallback? onAnalyze;
  final VoidCallback? onChoose;
  final VoidCallback? onCapture;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.hasBoundedHeight;

        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.primaryDark,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Image Ready',
                style: AppTypography.sectionTitle.copyWith(fontSize: 22),
              ),

              const SizedBox(height: 6),

              Text(
                'Review your image before starting classification.',
                style: AppTypography.bodySecondary.copyWith(height: 1.5),
              ),

              if (fileName != null) ...[
                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: Text(
                          fileName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (boundedHeight) const Spacer() else const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                  ),
                  onPressed: analyzing ? null : onAnalyze,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Analyze Fiber'),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: analyzing
                      ? null
                      : fromCamera && !kIsWeb
                      ? onCapture
                      : onChoose,
                  icon: Icon(
                    fromCamera && !kIsWeb
                        ? Icons.camera_alt_outlined
                        : Icons.photo_library_outlined,
                  ),
                  label: Text(
                    fromCamera && !kIsWeb ? 'Retake Photo' : 'Replace Image',
                  ),
                ),
              ),

              if (!kIsWeb && !fromCamera) ...[
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: analyzing ? null : onCapture,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Capture New Photo'),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: analyzing ? null : onRemove,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Image'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// GUIDELINES
// ============================================================

class _PhotoGuidelines extends StatelessWidget {
  const _PhotoGuidelines();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.light_mode_outlined,
        'Good Lighting',
        'Use enough light so visible fiber details are clear.',
      ),
      (
        Icons.center_focus_strong_outlined,
        'Keep Fiber Visible',
        'Keep the abaca fiber centered and unobstructed.',
      ),
      (
        Icons.blur_off_outlined,
        'Avoid Blur',
        'Use a steady and clearly focused photograph.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Before you submit',
              style: AppTypography.sectionTitle.copyWith(fontSize: 18),
            ),
            const Spacer(),
            Text(
              'PHOTO GUIDE',
              style: AppTypography.label.copyWith(
                color: AppColors.primary,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    _GuidelineCard(
                      icon: items[index].$1,
                      title: items[index].$2,
                      description: items[index].$3,
                    ),
                    if (index < items.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  Expanded(
                    child: _GuidelineCard(
                      icon: items[index].$1,
                      title: items[index].$2,
                      description: items[index].$3,
                    ),
                  ),
                  if (index < items.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GuidelineCard extends StatelessWidget {
  const _GuidelineCard({
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
            child: Icon(icon, color: AppColors.primary, size: 20),
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
        ],
      ),
    );
  }
}

// ============================================================
// ERRORS
// ============================================================

class _ImageErrorPanel extends StatelessWidget {
  const _ImageErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _ErrorBox(
      title: 'Unable to use this image',
      message: message,
      onClose: () {
        context.read<ImageSelectionProvider>().clearError();
      },
    );
  }
}

class _ClassificationError extends StatelessWidget {
  const _ClassificationError();

  @override
  Widget build(BuildContext context) {
    final classification = context.watch<ClassificationProvider>();

    final screenState = context.findAncestorStateOfType<_ClassifyScreenState>();

    return _ErrorBox(
      title: 'Unable to classify image',
      message:
          classification.error ??
          'The classification request failed. Please try again.',
      action: TextButton.icon(
        onPressed: classification.isAnalyzing
            ? null
            : screenState?._analyzeImage,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry'),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({
    required this.title,
    required this.message,
    this.onClose,
    this.action,
  });

  final String title;
  final String message;

  final VoidCallback? onClose;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTypography.bodySecondary.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          ?action,
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// ANALYZING OVERLAY
// ============================================================

class _AnalysisOverlay extends StatelessWidget {
  const _AnalysisOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColors.primaryDark.withValues(alpha: 0.76),
        alignment: Alignment.center,
        child: Container(
          width: 340,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 68,
                    height: 68,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_outlined,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Analyzing your fiber',
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 7),
              const Text(
                'ABAKASCAN is processing the selected image. Please keep this screen open.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DESKTOP SIDEBAR
// ============================================================

class _AnalyzeSidebar extends StatelessWidget {
  const _AnalyzeSidebar({
    required this.onDashboard,
    required this.onHistory,
    required this.onSamples,
    required this.onReports,
    required this.onSettings,
    required this.onAbout,
    required this.onLogout,
    required this.disabled,
  });

  final VoidCallback onDashboard;

  final Future<void> Function() onHistory;

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
          const _SidebarItem(
            icon: Icons.camera_alt_outlined,
            label: 'Analyze',
            selected: true,
          ),
          _SidebarItem(
            icon: Icons.history_rounded,
            label: 'History',
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
// BRAND / DECORATION
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

class _FiberLinePainter extends CustomPainter {
  const _FiberLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < 10; index++) {
      final y = size.height * (0.35 + index * 0.025);

      final path = Path()
        ..moveTo(-20, y)
        ..cubicTo(
          size.width * 0.25,
          y + 45,
          size.width * 0.68,
          y - 38,
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
