import 'package:flutter/material.dart';

import '../app/theme.dart';

class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({super.key});

  @override
  State<PublicHomeScreen> createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _howItWorksKey = GlobalKey();

  final GlobalKey _featuresKey = GlobalKey();

  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);

    _scrollController.dispose();

    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final show = _scrollController.offset > 700;

    if (show == _showBackToTop) {
      return;
    }

    setState(() {
      _showBackToTop = show;
    });
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) {
      return;
    }

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _scrollToHowItWorks() async {
    final target = _howItWorksKey.currentContext;

    if (target == null) {
      return;
    }

    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
      alignment: 0.04,
    );
  }

  Future<void> _scrollToFeatures() async {
    final target = _featuresKey.currentContext;

    if (target == null) {
      return;
    }

    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
      alignment: 0.04,
    );
  }

  Future<void> _openAbout() async {
    await Navigator.of(context).pushNamed('/about');
  }

  Future<void> _openClassify() async {
    await Navigator.of(context).pushNamed('/classify');
  }

  Future<void> _openLogin() async {
    await Navigator.of(context).pushNamed('/login');
  }

  Future<void> _openRegister() async {
    await Navigator.of(context).pushNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= AppBreakpoints.desktop;

            return Column(
              children: [
                _PublicNavbar(
                  desktop: desktop,
                  onHome: _scrollToTop,
                  onFeatures: _scrollToFeatures,
                  onHowItWorks: _scrollToHowItWorks,
                  onAbout: _openAbout,
                  onLogin: _openLogin,
                  onRegister: _openRegister,
                ),

                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          children: [
                            _HeroSection(
                              onGetStarted: _openRegister,
                              onHowItWorks: _scrollToHowItWorks,
                            ),

                            _SystemIntroduction(key: _featuresKey),

                            _HowItWorksSection(key: _howItWorksKey),

                            _AnalysisCallToAction(onAnalyze: _openClassify),

                            const _WhyAbakaScanSection(),

                            const _PlatformSection(),

                            _FinalCallToAction(
                              onRegister: _openRegister,
                              onLogin: _openLogin,
                            ),

                            const _PublicFooter(),
                          ],
                        ),
                      ),

                      if (_showBackToTop)
                        Positioned(
                          right: 22,
                          bottom: 22,
                          child: SafeArea(
                            child: Material(
                              color: AppColors.fiberBeige,
                              elevation: 5,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _scrollToTop,
                                child: const SizedBox(
                                  width: 54,
                                  height: 54,
                                  child: Icon(
                                    Icons.arrow_upward_rounded,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// NAVBAR
// ============================================================

class _PublicNavbar extends StatelessWidget {
  const _PublicNavbar({
    required this.desktop,
    required this.onHome,
    required this.onFeatures,
    required this.onHowItWorks,
    required this.onAbout,
    required this.onLogin,
    required this.onRegister,
  });

  final bool desktop;

  final VoidCallback onHome;
  final VoidCallback onFeatures;
  final VoidCallback onHowItWorks;
  final VoidCallback onAbout;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      color: AppColors.background,
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? AppSpacing.xxl : AppSpacing.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Row(
            children: [
              InkWell(
                onTap: onHome,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: _BrandLogo(darkText: true),
                ),
              ),

              const Spacer(),

              if (desktop) ...[
                _NavTextButton(label: 'Home', onPressed: onHome),

                _NavTextButton(label: 'Features', onPressed: onFeatures),

                _NavTextButton(label: 'How It Works', onPressed: onHowItWorks),

                _NavTextButton(label: 'About', onPressed: onAbout),

                const SizedBox(width: AppSpacing.md),

                OutlinedButton(onPressed: onLogin, child: const Text('Log In')),

                const SizedBox(width: AppSpacing.sm),

                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                  ),
                  onPressed: onRegister,
                  child: const Text('Get Started'),
                ),
              ] else
                PopupMenuButton<_PublicMenuAction>(
                  tooltip: 'Menu',
                  icon: const Icon(Icons.menu_rounded),
                  onSelected: (action) {
                    switch (action) {
                      case _PublicMenuAction.home:
                        onHome();
                        break;

                      case _PublicMenuAction.features:
                        onFeatures();
                        break;

                      case _PublicMenuAction.howItWorks:
                        onHowItWorks();
                        break;

                      case _PublicMenuAction.about:
                        onAbout();
                        break;

                      case _PublicMenuAction.login:
                        onLogin();
                        break;

                      case _PublicMenuAction.register:
                        onRegister();
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(
                        value: _PublicMenuAction.home,
                        child: _MenuItemContent(
                          icon: Icons.home_outlined,
                          label: 'Home',
                        ),
                      ),

                      PopupMenuItem(
                        value: _PublicMenuAction.features,
                        child: _MenuItemContent(
                          icon: Icons.grid_view_outlined,
                          label: 'Features',
                        ),
                      ),

                      PopupMenuItem(
                        value: _PublicMenuAction.howItWorks,
                        child: _MenuItemContent(
                          icon: Icons.route_outlined,
                          label: 'How It Works',
                        ),
                      ),

                      PopupMenuItem(
                        value: _PublicMenuAction.about,
                        child: _MenuItemContent(
                          icon: Icons.eco_outlined,
                          label: 'About',
                        ),
                      ),

                      PopupMenuDivider(),

                      PopupMenuItem(
                        value: _PublicMenuAction.login,
                        child: _MenuItemContent(
                          icon: Icons.login_rounded,
                          label: 'Log In',
                        ),
                      ),

                      PopupMenuItem(
                        value: _PublicMenuAction.register,
                        child: _MenuItemContent(
                          icon: Icons.person_add_outlined,
                          label: 'Get Started',
                        ),
                      ),
                    ];
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PublicMenuAction { home, features, howItWorks, about, login, register }

class _NavTextButton extends StatelessWidget {
  const _NavTextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: AppTypography.bodySecondary.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MenuItemContent extends StatelessWidget {
  const _MenuItemContent({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.primary),

        const SizedBox(width: AppSpacing.sm),

        Text(label),
      ],
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onGetStarted, required this.onHowItWorks});

  final VoidCallback onGetStarted;
  final VoidCallback onHowItWorks;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      child: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _LandingFiberPainter()),
            ),
          ),

          Positioned(
            right: -150,
            top: -180,
            child: Container(
              width: 470,
              height: 470,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.13),
              ),
            ),
          ),

          Positioned(
            left: -170,
            bottom: -240,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.fiberBeige.withValues(alpha: 0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 82,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 860;

                    final content = _HeroContent(
                      compact: compact,
                      onGetStarted: onGetStarted,
                      onHowItWorks: onHowItWorks,
                    );

                    const visual = _HeroFiberVisual();

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [content, const SizedBox(height: 52), visual],
                      );
                    }

                    return const SizedBox(
                      height: 560,
                      child: _HeroDesktopLayout(),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDesktopLayout extends StatelessWidget {
  const _HeroDesktopLayout();

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorWidgetOfExactType<_HeroSection>();

    return Row(
      children: [
        Expanded(
          flex: 11,
          child: _HeroContent(
            compact: false,
            onGetStarted: parent!.onGetStarted,
            onHowItWorks: parent.onHowItWorks,
          ),
        ),

        const SizedBox(width: 64),

        const Expanded(flex: 8, child: _HeroFiberVisual()),
      ],
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.compact,
    required this.onGetStarted,
    required this.onHowItWorks,
  });

  final bool compact;

  final VoidCallback onGetStarted;
  final VoidCallback onHowItWorks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'FIBER INTELLIGENCE FOR A STRONGER TOMORROW',
          style: AppTypography.label.copyWith(
            color: AppColors.fiberBeige,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            height: 1.4,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        Text(
          'See the quality\nin every fiber.',
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.background,
            fontSize: compact ? 48 : 70,
            height: 0.98,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'ABAKASCAN uses image processing and machine learning to analyze abaca fiber images and return a predicted grade with classification confidence.',
            style: AppTypography.body.copyWith(
              color: AppColors.background.withValues(alpha: 0.78),
              fontSize: 17,
              height: 1.7,
            ),
          ),
        ),

        const SizedBox(height: 34),

        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.fiberBeige,
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 17,
                ),
              ),
              onPressed: onGetStarted,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Get Started'),
            ),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 17,
                ),
                side: BorderSide(
                  color: AppColors.background.withValues(alpha: 0.30),
                ),
              ),
              onPressed: onHowItWorks,
              icon: const Icon(Icons.south_rounded),
              label: const Text('Explore How It Works'),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xxl),

        const Wrap(
          spacing: 24,
          runSpacing: 14,
          children: [
            _HeroFeature(icon: Icons.image_outlined, text: 'Image-based'),

            _HeroFeature(icon: Icons.memory_outlined, text: 'Machine learning'),

            _HeroFeature(icon: Icons.devices_outlined, text: 'Web + mobile'),
          ],
        ),
      ],
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.fiberBeige),

        const SizedBox(width: 7),

        Text(
          text,
          style: AppTypography.caption.copyWith(
            color: AppColors.background.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// HERO VISUAL
// ============================================================

class _HeroFiberVisual extends StatelessWidget {
  const _HeroFiberVisual();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.92,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 520),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _FiberBundlePainter()),
            ),

            Positioned(
              left: 24,
              top: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ABACA',
                  style: AppTypography.label.copyWith(
                    color: AppColors.fiberBeige,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            Positioned(
              right: 28,
              bottom: 34,
              child: SizedBox(
                width: 185,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.image_search_outlined,
                      color: AppColors.primaryDark,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Image Analysis',
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Fiber patterns become classification information.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Positioned(
              left: 30,
              bottom: 34,
              child: Icon(
                Icons.eco_outlined,
                size: 58,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SYSTEM INTRODUCTION
// ============================================================

class _SystemIntroduction extends StatelessWidget {
  const _SystemIntroduction({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageSection(
      verticalPadding: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            eyebrow: 'IMAGE CLASSIFICATION',
            title: 'A focused workflow built around the fiber image.',
            description: 'ABAKASCAN keeps the interaction simple while image preparation and machine-learning analysis happen behind the interface.',
          ),

          const SizedBox(height: 46),

          LayoutBuilder(
            builder: (context, constraints) {
              const cards = [
                _FeatureCard(
                  number: '01',
                  icon: Icons.add_photo_alternate_outlined,
                  title: 'Upload or Capture',
                  description: 'Provide a clear image of an abaca fiber sample from the web or a supported mobile device.',
                ),
                _FeatureCard(
                  number: '02',
                  icon: Icons.tune_outlined,
                  title: 'Image Processing',
                  description: 'The selected image is prepared for the classification workflow.',
                ),
                _FeatureCard(
                  number: '03',
                  icon: Icons.memory_outlined,
                  title: 'Model Analysis',
                  description: 'The trained model evaluates image-supported visual patterns.',
                ),
                _FeatureCard(
                  number: '04',
                  icon: Icons.fact_check_outlined,
                  title: 'Review Result',
                  description: 'View the predicted grade and classification confidence returned by the model.',
                ),
              ];

              // MOBILE
              // Let each card use its natural height.
              if (constraints.maxWidth < 650) {
                return Column(
                  children: [
                    for (var index = 0; index < cards.length; index++) ...[
                      cards[index],
                      if (index < cards.length - 1)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              }

              // TABLET
              // Every grid item is exactly the same height.
              if (constraints.maxWidth < 1000) {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  mainAxisExtent: 260,
                  children: cards,
                );
              }

              // DESKTOP
              // Give the entire row one fixed height so
              // every card stretches to exactly the same size.
              return SizedBox(
                height: 260,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < cards.length; index++) ...[
                      Expanded(child: cards[index]),
                      if (index < cards.length - 1)
                        const SizedBox(width: AppSpacing.md),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOW IT WORKS
// ============================================================

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceMuted,
      child: _PageSection(
        verticalPadding: 104,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(
              eyebrow: 'HOW IT WORKS',
              title: 'From image to classification in four steps.',
              description: 'The same core process is shared between the web and mobile experience.',
            ),

            const SizedBox(height: 52),

            LayoutBuilder(
              builder: (context, constraints) {
                const steps = [
                  _WorkflowCard(
                    number: '01',
                    icon: Icons.camera_alt_outlined,
                    title: 'Provide the Fiber Image',
                    description: 'Upload an existing image or capture one using a supported mobile device.',
                  ),

                  _WorkflowCard(
                    number: '02',
                    icon: Icons.visibility_outlined,
                    title: 'Review Before Submission',
                    description: 'Check the selected image and replace or retake it when necessary.',
                  ),

                  _WorkflowCard(
                    number: '03',
                    icon: Icons.document_scanner_outlined,
                    title: 'Run Classification',
                    description: 'Submit the image to the ABAKASCAN classification workflow.',
                  ),

                  _WorkflowCard(
                    number: '04',
                    icon: Icons.analytics_outlined,
                    title: 'Review the Result',
                    description: 'View the predicted grade, confidence, and saved record information.',
                  ),
                ];

                if (constraints.maxWidth < 820) {
                  return Column(
                    children: [
                      for (var index = 0; index < steps.length; index++) ...[
                        steps[index],

                        if (index < steps.length - 1)
                          const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < steps.length; index++) ...[
                      Expanded(child: steps[index]),

                      if (index < steps.length - 1)
                        const Padding(
                          padding: EdgeInsets.only(top: 65),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.borderStrong,
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MID-PAGE CTA
// ============================================================

class _AnalysisCallToAction extends StatelessWidget {
  const _AnalysisCallToAction({required this.onAnalyze});

  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return _PageSection(
      verticalPadding: 92,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _LandingFiberPainter(subtle: true)),
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;

                final text = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READY TO ANALYZE?',
                      style: AppTypography.label.copyWith(
                        color: AppColors.fiberBeige,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Start with a clear abaca fiber image.',
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.background,
                        fontSize: 27,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Choose an image, review it, and continue into the classification workflow.',
                      style: AppTypography.bodySecondary.copyWith(
                        color: AppColors.background.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                );

                final button = FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.fiberBeige,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                  ),
                  onPressed: onAnalyze,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Analyze Fiber'),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      text,

                      const SizedBox(height: AppSpacing.lg),

                      button,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: text),

                    const SizedBox(width: AppSpacing.xl),

                    button,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WHY ABAKASCAN
// ============================================================

class _WhyAbakaScanSection extends StatelessWidget {
  const _WhyAbakaScanSection();

  @override
  Widget build(BuildContext context) {
    return _PageSection(
      verticalPadding: 100,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeading(
                eyebrow: 'WHY ABAKASCAN',
                title: 'Agriculture meets computer vision.',
                description: 'The project brings a focused image-classification workflow into a clean digital interface for abaca fiber analysis.',
              ),

              const SizedBox(height: AppSpacing.xl),

              const _BenefitItem(
                icon: Icons.speed_outlined,
                title: 'Focused Workflow',
                description: 'Image selection, classification, results, and history stay within one consistent system.',
              ),

              const SizedBox(height: AppSpacing.md),

              const _BenefitItem(
                icon: Icons.devices_outlined,
                title: 'Responsive Access',
                description: 'The same Flutter codebase adapts the experience across desktop, tablet, and mobile layouts.',
              ),

              const SizedBox(height: AppSpacing.md),

              const _BenefitItem(
                icon: Icons.history_outlined,
                title: 'Classification Records',
                description: 'Authenticated users can return to saved classifications through their history.',
              ),
            ],
          );

          const visual = _AgricultureVisual();

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [content, const SizedBox(height: 48), visual],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: content),

              const SizedBox(width: 70),

              const Expanded(child: visual),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// AGRICULTURE VISUAL
// ============================================================

class _AgricultureVisual extends StatelessWidget {
  const _AgricultureVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 440,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceSage,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _LeafFieldPainter()),
          ),

          Positioned(
            left: 34,
            top: 34,
            child: Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco_outlined,
                color: AppColors.fiberBeige,
                size: 36,
              ),
            ),
          ),

          Positioned(
            left: 34,
            right: 34,
            bottom: 34,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ABACA + TECHNOLOGY',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),

                  SizedBox(height: AppSpacing.sm),

                  Text(
                    'Designed around the fiber.',
                    style: AppTypography.sectionTitle,
                  ),

                  SizedBox(height: AppSpacing.sm),

                  Text(
                    'A visual language inspired by abaca leaves, natural fibers, and agricultural material.',
                    style: AppTypography.bodySecondary,
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

// ============================================================
// PLATFORM SECTION
// ============================================================

class _PlatformSection extends StatelessWidget {
  const _PlatformSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: _PageSection(
        verticalPadding: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(
              eyebrow: 'WEB + MOBILE',
              title: 'A responsive experience for different devices.',
              description: 'The interface keeps the same core workflow while adapting the interaction to the available screen and device capabilities.',
            ),

            const SizedBox(height: 44),

            LayoutBuilder(
              builder: (context, constraints) {
                const web = _PlatformCard(
                  icon: Icons.language_outlined,
                  eyebrow: 'WEB',
                  title: 'Desktop and Browser',
                  description: 'Upload images, review classification information in wider layouts, and navigate through the full workspace.',
                  feature: 'UPLOAD',
                );

                const mobile = _PlatformCard(
                  icon: Icons.smartphone_outlined,
                  eyebrow: 'MOBILE',
                  title: 'Phone Experience',
                  description: 'Capture a new image or choose one from the device gallery using a layout designed for touch.',
                  feature: 'CAPTURE',
                );

                if (constraints.maxWidth < 720) {
                  return const Column(
                    children: [
                      web,

                      SizedBox(height: AppSpacing.md),

                      mobile,
                    ],
                  );
                }

                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: web),

                    SizedBox(width: AppSpacing.md),

                    Expanded(child: mobile),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FINAL CTA
// ============================================================

class _FinalCallToAction extends StatelessWidget {
  const _FinalCallToAction({required this.onRegister, required this.onLogin});

  final VoidCallback onRegister;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return _PageSection(
      verticalPadding: 92,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: 50,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(26),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;

            final text = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'START WITH ABAKASCAN',
                  style: AppTypography.label.copyWith(
                    color: AppColors.fiberBeige,
                    letterSpacing: 1.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  'Bring fiber classification into one digital workflow.',
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.background,
                    fontSize: 29,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  'Create an account or sign in to continue.',
                  style: AppTypography.bodySecondary.copyWith(
                    color: AppColors.background.withValues(alpha: 0.70),
                  ),
                ),
              ],
            );

            final actions = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.fiberBeige,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  onPressed: onRegister,
                  child: const Text('Create Account'),
                ),

                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.background,
                    side: BorderSide(
                      color: AppColors.background.withValues(alpha: 0.30),
                    ),
                  ),
                  onPressed: onLogin,
                  child: const Text('Log In'),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,

                  const SizedBox(height: AppSpacing.lg),

                  actions,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: text),

                const SizedBox(width: 50),

                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// FOOTER
// ============================================================

class _PublicFooter extends StatelessWidget {
  const _PublicFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 34,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;

              final brand = const _FooterBrand();

              final description = Text(
                'Abaca Fiber Grade Classification System',
                textAlign: compact ? TextAlign.center : TextAlign.right,
                style: AppTypography.caption.copyWith(
                  color: AppColors.background.withValues(alpha: 0.55),
                ),
              );

              if (compact) {
                return Column(
                  children: [
                    brand,

                    const SizedBox(height: AppSpacing.md),

                    description,
                  ],
                );
              }

              return Row(children: [brand, const Spacer(), description]);
            },
          ),
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return const _BrandLogo();
  }
}

// ============================================================
// SHARED LANDING ELEMENTS
// ============================================================

class _PageSection extends StatelessWidget {
  const _PageSection({required this.child, required this.verticalPadding});

  final Widget child;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: verticalPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: AppTypography.label.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.7,
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Text(
            title,
            style: AppTypography.pageTitle.copyWith(
              color: AppColors.primaryDark,
              fontSize: 38,
              height: 1.12,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            description,
            style: AppTypography.bodySecondary.copyWith(height: 1.7),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FEATURE CARD
// ============================================================

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
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
                child: Icon(icon, color: AppColors.primary, size: 21),
              ),

              const Spacer(),

              Text(
                number,
                style: AppTypography.label.copyWith(
                  color: AppColors.fiberBeige,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 18)),

          const SizedBox(height: AppSpacing.sm),

          Text(
            description,
            style: AppTypography.bodySecondary.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WORKFLOW CARD
// ============================================================

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  number,
                  style: AppTypography.label.copyWith(
                    color: AppColors.fiberBeige,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const Spacer(),

              Icon(icon, color: AppColors.primary, size: 26),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(title, style: AppTypography.cardTitle),

          const SizedBox(height: AppSpacing.sm),

          Text(
            description,
            style: AppTypography.bodySecondary.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BENEFIT ITEM
// ============================================================

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.cardTitle),

              const SizedBox(height: 5),

              Text(
                description,
                style: AppTypography.bodySecondary.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PLATFORM CARD
// ============================================================

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.feature,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final String feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 25),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fiberBeigeSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  feature,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            eyebrow,
            style: AppTypography.label.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(title, style: AppTypography.sectionTitle),

          const SizedBox(height: AppSpacing.md),

          Text(
            description,
            style: AppTypography.bodySecondary.copyWith(height: 1.65),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BRAND
// ============================================================

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({this.darkText = false});

  final bool darkText;

  @override
  Widget build(BuildContext context) {
    final foreground = darkText ? AppColors.primaryDark : AppColors.background;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.eco_outlined,
          color: darkText ? AppColors.primary : AppColors.fiberBeige,
          size: 22,
        ),

        const SizedBox(width: AppSpacing.sm),

        Text(
          'ABAKASCAN',
          style: AppTypography.label.copyWith(
            color: foreground,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FIBER PAINTER
// ============================================================

class _LandingFiberPainter extends CustomPainter {
  const _LandingFiberPainter({this.subtle = false});

  final bool subtle;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < 7; index++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = index.isEven ? 1.3 : 0.9
        ..color = AppColors.fiberBeige.withValues(alpha: subtle ? 0.07 : 0.09);

      final y = size.height * (0.10 + index * 0.13);

      final path = Path()
        ..moveTo(-40, y)
        ..cubicTo(
          size.width * 0.22,
          y - 45,
          size.width * 0.42,
          y + 48,
          size.width * 0.63,
          y,
        )
        ..cubicTo(
          size.width * 0.81,
          y - 35,
          size.width * 0.93,
          y + 38,
          size.width + 45,
          y - 8,
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================
// FIBER BUNDLE VISUAL
// ============================================================

class _FiberBundlePainter extends CustomPainter {
  const _FiberBundlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = AppColors.fiberBeigeSoft;

    canvas.drawRect(Offset.zero & size, background);

    for (var index = 0; index < 22; index++) {
      final ratio = index / 21;

      final startY = size.height * (0.10 + ratio * 0.76);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = index % 4 == 0 ? 4 : 2.1
        ..strokeCap = StrokeCap.round
        ..color = index % 5 == 0
            ? AppColors.primaryDark.withValues(alpha: 0.28)
            : AppColors.fiberBeige.withValues(alpha: 0.68);

      final path = Path()
        ..moveTo(-30, startY)
        ..cubicTo(
          size.width * 0.24,
          startY - 85,
          size.width * 0.55,
          startY + 72,
          size.width + 40,
          startY - 35 + (index % 3) * 18,
        );

      canvas.drawPath(path, paint);
    }

    final leafPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.20);

    canvas.save();
    canvas.translate(size.width * 0.60, size.height * 0.25);
    canvas.rotate(-0.50);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.56,
        height: size.height * 0.15,
      ),
      leafPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================
// LEAF FIELD
// ============================================================

class _LeafFieldPainter extends CustomPainter {
  const _LeafFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.primary.withValues(alpha: 0.20);

    for (var index = 0; index < 8; index++) {
      final y = size.height * (0.10 + index * 0.11);

      final path = Path()
        ..moveTo(-20, y)
        ..quadraticBezierTo(size.width * 0.48, y - 80, size.width + 20, y + 20);

      canvas.drawPath(path, linePaint);
    }

    final leafPaint = Paint()
      ..color = AppColors.primaryDark.withValues(alpha: 0.08);

    for (var index = 0; index < 5; index++) {
      final center = Offset(
        size.width * (0.22 + index * 0.16),
        size.height * (0.24 + (index % 2) * 0.17),
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-0.6 + index * 0.18);

      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 145, height: 38),
        leafPaint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
