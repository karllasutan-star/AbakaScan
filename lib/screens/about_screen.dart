import 'package:flutter/material.dart';

import '../app/theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final ScrollController _scrollController = ScrollController();

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

  void _goBack(BuildContext context) {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.popUntil((route) => route.isFirst);
  }

  Future<void> _openClassify(BuildContext context) async {
    await Navigator.of(context).pushNamed('/classify');
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,

        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            _goBack(context);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),

        titleSpacing: 0,

        title: Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: const _Brand(darkText: true),
          ),
        ),

        actions: [
          if (compact)
            IconButton(
              tooltip: 'Analyze',
              onPressed: () {
                _openClassify(context);
              },
              icon: const Icon(Icons.camera_alt_outlined),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: () {
                  _openClassify(context);
                },
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Analyze'),
              ),
            ),
        ],
      ),

      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1320),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _AboutHero(),

                        const SizedBox(height: 110),

                        const _AboutStorySection(),

                        const SizedBox(height: 130),

                        const _WorkflowSection(),

                        const SizedBox(height: 130),

                        const _UsersSection(),

                        const SizedBox(height: 130),

                        const _ScopeSection(),

                        const SizedBox(height: 100),

                        _BottomAction(
                          onAnalyze: () {
                            _openClassify(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
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
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        return SizedBox(
          width: double.infinity,
          height: compact ? 500 : 540,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
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
                        Color(0xFA0F3D2E),
                        Color(0xDB0F3D2E),
                        Color(0x760F3D2E),
                        Color(0x120F3D2E),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(compact ? 28 : 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Brand(),

                      const Spacer(),

                      Text(
                        'ABOUT ABAKASCAN',
                        style: AppTypography.label.copyWith(
                          color: AppColors.fiberBeige,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.3,
                        ),
                      ),

                      const SizedBox(height: 18),

                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Text(
                          'Fiber intelligence\nbuilt around images.',
                          style: AppTypography.pageTitle.copyWith(
                            color: Colors.white,
                            fontSize: compact ? 40 : 58,
                            height: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Text(
                          'ABAKASCAN uses digital images, image processing, and machine learning to assist with abaca fiber grade classification.',
                          style: AppTypography.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontSize: compact ? 15 : 17,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// ABOUT STORY
// ============================================================

class _AboutStorySection extends StatelessWidget {
  const _AboutStorySection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StoryText(),

              const SizedBox(height: 55),

              const _StoryVisual(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(flex: 10, child: _StoryText()),

            const SizedBox(width: 85),

            const Expanded(flex: 9, child: _StoryVisual()),
          ],
        );
      },
    );
  }
}

class _StoryText extends StatelessWidget {
  const _StoryText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow(text: 'ABOUT THE SYSTEM'),

        const SizedBox(height: 18),

        Text(
          'A focused approach to\nabaca fiber analysis.',
          style: AppTypography.pageTitle.copyWith(fontSize: 47, height: 1.07),
        ),

        const SizedBox(height: 28),

        Text(
          'ABAKASCAN is designed as a computer-assisted tool for analyzing digital images of abaca fiber. Users can provide an image, allow the system to process it through the trained model, and review the predicted grade together with classification confidence.',
          style: AppTypography.bodySecondary.copyWith(
            fontSize: 17,
            height: 1.8,
          ),
        ),

        const SizedBox(height: 48),

        const _EditorialPoint(
          number: '01',
          title: 'Digital image input',
          description: 'Capture a fiber image using a supported mobile device or select an existing image from the device.',
        ),

        const SizedBox(height: 38),

        const _EditorialPoint(
          number: '02',
          title: 'Model-based classification',
          description: 'The backend prepares the submitted image and evaluates it using the trained classification model.',
        ),

        const SizedBox(height: 38),

        const _EditorialPoint(
          number: '03',
          title: 'Clear classification output',
          description: 'The system presents a predicted grade together with the classification confidence returned by the model.',
        ),
      ],
    );
  }
}

class _EditorialPoint extends StatelessWidget {
  const _EditorialPoint({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            number,
            style: AppTypography.pageTitle.copyWith(
              color: AppColors.fiberBeige,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                description,
                style: AppTypography.bodySecondary.copyWith(
                  fontSize: 16,
                  height: 1.7,
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
// STORY VISUAL
// ============================================================

class _StoryVisual extends StatelessWidget {
  const _StoryVisual();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _SafeAssetImage(
              asset: 'assets/images/about_story_visual.png',
              fit: BoxFit.cover,
            ),

            Positioned(
              top: 30,
              left: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ABACA',
                  style: AppTypography.label.copyWith(
                    color: AppColors.fiberBeige,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 50,
              bottom: 50,
              right: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.image_search_outlined,
                    color: AppColors.primaryDark,
                    size: 30,
                  ),

                  const SizedBox(height: 13),

                  Text(
                    'IMAGE ANALYSIS',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.7,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(width: 52, height: 2, color: AppColors.fiberBeige),

                  const SizedBox(height: 15),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 310),
                    child: Text(
                      'Fiber patterns become classification information.',
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 22,
                        height: 1.35,
                      ),
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

class _WorkflowSection extends StatelessWidget {
  const _WorkflowSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;

        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              const Positioned.fill(
                child: _SafeAssetImage(
                  asset: 'assets/images/about_workflow_visual.png',
                  fit: BoxFit.cover,
                ),
              ),

              Positioned.fill(
                child: Container(
                  color: AppColors.surface.withValues(alpha: 0.18),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 24 : 46,
                  vertical: compact ? 38 : 58,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _WorkflowHeader(),

                    SizedBox(height: compact ? 45 : 62),

                    if (compact)
                      const _MobileWorkflow()
                    else
                      const _DesktopWorkflow(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkflowHeader extends StatelessWidget {
  const _WorkflowHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 64, height: 2, color: AppColors.fiberBeige),

                const SizedBox(width: 14),

                const _Eyebrow(text: 'HOW IT WORKS'),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              'A simple path from\nfiber image to result.',
              style: AppTypography.pageTitle.copyWith(
                fontSize: compact ? 38 : 50,
                height: 1.03,
              ),
            ),

            const SizedBox(height: 22),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Text(
                'The process is designed to keep image submission and classification easy to understand from beginning to end.',
                style: AppTypography.bodySecondary.copyWith(
                  fontSize: 17,
                  height: 1.7,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// DESKTOP WORKFLOW
// ============================================================

class _DesktopWorkflow extends StatelessWidget {
  const _DesktopWorkflow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(
          child: _WorkflowCard(
            number: '01',
            icon: Icons.camera_alt_outlined,
            title: 'Capture',
            description: 'Provide a clear abaca fiber image.',
            visual: _WorkflowVisual.capture,
          ),
        ),

        _WorkflowConnector(),

        Expanded(
          child: _WorkflowCard(
            number: '02',
            icon: Icons.tune_rounded,
            title: 'Prepare',
            description: 'The image is prepared before classification.',
            visual: _WorkflowVisual.prepare,
          ),
        ),

        _WorkflowConnector(),

        Expanded(
          child: _WorkflowCard(
            number: '03',
            icon: Icons.psychology_outlined,
            title: 'Analyze',
            description: 'The trained model evaluates the image.',
            visual: _WorkflowVisual.analyze,
          ),
        ),

        _WorkflowConnector(),

        Expanded(
          child: _WorkflowCard(
            number: '04',
            icon: Icons.bar_chart_rounded,
            title: 'Result',
            description: 'Review the predicted grade and confidence.',
            visual: _WorkflowVisual.result,
          ),
        ),
      ],
    );
  }
}

class _MobileWorkflow extends StatelessWidget {
  const _MobileWorkflow();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _WorkflowCard(
          number: '01',
          icon: Icons.camera_alt_outlined,
          title: 'Capture',
          description: 'Provide a clear abaca fiber image.',
          visual: _WorkflowVisual.capture,
        ),

        _MobileWorkflowConnector(),

        _WorkflowCard(
          number: '02',
          icon: Icons.tune_rounded,
          title: 'Prepare',
          description: 'The image is prepared before classification.',
          visual: _WorkflowVisual.prepare,
        ),

        _MobileWorkflowConnector(),

        _WorkflowCard(
          number: '03',
          icon: Icons.psychology_outlined,
          title: 'Analyze',
          description: 'The trained model evaluates the image.',
          visual: _WorkflowVisual.analyze,
        ),

        _MobileWorkflowConnector(),

        _WorkflowCard(
          number: '04',
          icon: Icons.bar_chart_rounded,
          title: 'Result',
          description: 'Review the predicted grade and confidence.',
          visual: _WorkflowVisual.result,
        ),
      ],
    );
  }
}

enum _WorkflowVisual { capture, prepare, analyze, result }

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    required this.visual,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;
  final _WorkflowVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.07),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                number,
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.fiberBeige,
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const Spacer(),

              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.sage),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 24),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(width: 45, height: 3, color: AppColors.fiberBeige),

          const SizedBox(height: 18),

          Text(
            title,
            style: AppTypography.sectionTitle.copyWith(
              color: AppColors.primaryDark,
              fontSize: 22,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            description,
            style: AppTypography.bodySecondary.copyWith(
              fontSize: 15,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 145,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _WorkflowVisualPanel(visual: visual),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowVisualPanel extends StatelessWidget {
  const _WorkflowVisualPanel({required this.visual});

  final _WorkflowVisual visual;

  @override
  Widget build(BuildContext context) {
    switch (visual) {
      case _WorkflowVisual.capture:
        return Stack(
          fit: StackFit.expand,
          children: [
            const _SafeAssetImage(
              asset: 'assets/images/about_story_visual.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomRight,
            ),

            Container(color: AppColors.surface.withValues(alpha: 0.10)),

            const Center(
              child: Icon(
                Icons.center_focus_strong,
                color: AppColors.primaryDark,
                size: 40,
              ),
            ),
          ],
        );

      case _WorkflowVisual.prepare:
        return Stack(
          fit: StackFit.expand,
          children: [
            const _SafeAssetImage(
              asset: 'assets/images/about_story_visual.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomRight,
            ),

            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 100,
              child: Container(color: Colors.white.withValues(alpha: 0.42)),
            ),

            Align(
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        );

      case _WorkflowVisual.analyze:
        return Stack(
          fit: StackFit.expand,
          children: [
            const _SafeAssetImage(
              asset: 'assets/images/about_scope_bg.png',
              fit: BoxFit.cover,
            ),

            Container(color: AppColors.primaryDark.withValues(alpha: 0.30)),

            Positioned(
              left: 24,
              top: 24,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
              ),
            ),

            Positioned(
              right: 25,
              bottom: 23,
              child: Container(
                width: 88,
                height: 62,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.fiberBeige, width: 2),
                ),
              ),
            ),
          ],
        );

      case _WorkflowVisual.result:
        return Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'A',
                          style: AppTypography.pageTitle.copyWith(
                            color: AppColors.primaryDark,
                            fontSize: 38,
                          ),
                        ),

                        const Text(
                          'Predicted Grade',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),

                  Container(width: 1, height: 52, color: AppColors.border),

                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '92%',
                          style: AppTypography.sectionTitle.copyWith(
                            color: AppColors.primaryDark,
                            fontSize: 27,
                          ),
                        ),

                        const Text('Confidence', style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(
                  value: 0.92,
                  minHeight: 8,
                  backgroundColor: AppColors.sage,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _WorkflowConnector extends StatelessWidget {
  const _WorkflowConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 120, 8, 0),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.fiberBeigeSoft),
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: AppColors.fiberBeige,
        ),
      ),
    );
  }
}

class _MobileWorkflowConnector extends StatelessWidget {
  const _MobileWorkflowConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.fiberBeigeSoft),
        ),
        child: const Icon(
          Icons.arrow_downward_rounded,
          color: AppColors.fiberBeige,
        ),
      ),
    );
  }
}

// ============================================================
// INTENDED USERS
// ============================================================

class _UsersSection extends StatelessWidget {
  const _UsersSection();

  @override
  Widget build(BuildContext context) {
    const users = [
      _UserData(Icons.agriculture_outlined, 'Farmers'),
      _UserData(Icons.factory_outlined, 'Fiber Processors'),
      _UserData(Icons.groups_outlined, 'Cooperatives'),
      _UserData(Icons.shopping_bag_outlined, 'Buyers'),
      _UserData(Icons.science_outlined, 'Agricultural Researchers'),
      _UserData(Icons.person_outline, 'Other Stakeholders'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        return SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _Eyebrow(text: 'INTENDED USERS'),

              const SizedBox(height: 18),

              Text(
                'Built for people working\nwith abaca fiber.',
                textAlign: TextAlign.center,
                style: AppTypography.pageTitle.copyWith(
                  fontSize: compact ? 37 : 46,
                  height: 1.07,
                ),
              ),

              const SizedBox(height: 24),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Text(
                  'ABAKASCAN provides an accessible image-based reference for people working with, studying, processing, or evaluating abaca fiber.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary.copyWith(
                    fontSize: 16,
                    height: 1.75,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 14,
                    runSpacing: 14,
                    children: [for (final user in users) _UserChip(data: user)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserData {
  const _UserData(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.data});

  final _UserData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.sage),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, color: AppColors.primaryDark, size: 19),

          const SizedBox(width: 10),

          Text(
            data.label,
            style: AppTypography.body.copyWith(
              color: AppColors.primaryDark,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RESPONSIBLE SCOPE
// ============================================================

class _ScopeSection extends StatelessWidget {
  const _ScopeSection();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          const Positioned.fill(
            child: _SafeAssetImage(
              asset: 'assets/images/about_scope_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF0F3D2E),
                    Color(0xF80F3D2E),
                    Color(0xDF0F3D2E),
                    Color(0xA80F3D2E),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 62),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESPONSIBLE SCOPE',
                  style: AppTypography.label.copyWith(
                    color: AppColors.fiberBeige,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.1,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'What the system can —\nand cannot — claim.',
                  style: AppTypography.pageTitle.copyWith(
                    color: Colors.white,
                    fontSize: 44,
                    height: 1.07,
                  ),
                ),

                const SizedBox(height: 48),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 780;

                    const left = Column(
                      children: [
                        _ScopePoint(
                          icon: Icons.image_search_outlined,
                          title: 'Image-based analysis',
                          description: 'The system evaluates visual information represented in the submitted digital image.',
                        ),

                        SizedBox(height: 34),

                        _ScopePoint(
                          icon: Icons.dataset_outlined,
                          title: 'Supported model classes',
                          description: 'Predictions are limited to grade classes represented in the verified training data.',
                        ),
                      ],
                    );

                    const right = Column(
                      children: [
                        _ScopePoint(
                          icon: Icons.straighten_outlined,
                          title: 'No direct physical measurement',
                          description: 'Image classification does not directly measure tensile strength or other laboratory characteristics.',
                        ),

                        SizedBox(height: 34),

                        _ScopePoint(
                          icon: Icons.rule_outlined,
                          title: 'Not official grading',
                          description: 'Qualified grading, calibrated measurement, physical testing, and laboratory procedures remain separate.',
                        ),
                      ],
                    );

                    if (stacked) {
                      return const Column(
                        children: [left, SizedBox(height: 34), right],
                      );
                    }

                    return const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        SizedBox(width: 70),
                        Expanded(child: right),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 50),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.fiberBeige,
                        size: 23,
                      ),

                      SizedBox(width: 14),

                      Expanded(
                        child: Text(
                          'ABAKASCAN provides image-based predictions and does not replace official abaca fiber grading procedures.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.65,
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
    );
  }
}

class _ScopePoint extends StatelessWidget {
  const _ScopePoint({
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
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.fiberBeige, size: 22),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.cardTitle.copyWith(
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                description,
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 14,
                  height: 1.7,
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
// BOTTOM ACTION
// ============================================================

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.onAnalyze});

  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Ready to analyze a fiber image?',
            textAlign: TextAlign.center,
            style: AppTypography.sectionTitle.copyWith(
              color: AppColors.primaryDark,
              fontSize: 30,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Choose an image and continue to the ABAKASCAN analysis workspace.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary.copyWith(fontSize: 16),
          ),

          const SizedBox(height: 30),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 19),
            ),
            onPressed: onAnalyze,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Analyze Fiber'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REUSABLE
// ============================================================

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.label.copyWith(
        color: AppColors.primary,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.1,
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.darkText = false});

  final bool darkText;

  @override
  Widget build(BuildContext context) {
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
            color: darkText ? AppColors.primaryDark : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.3,
          ),
        ),
      ],
    );
  }
}

class _SafeAssetImage extends StatelessWidget {
  const _SafeAssetImage({
    required this.asset,
    required this.fit,
    this.alignment = Alignment.center,
  });

  final String asset;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.surfaceSage,
          alignment: Alignment.center,
          child: const Icon(
            Icons.eco_outlined,
            color: AppColors.primary,
            size: 42,
          ),
        );
      },
    );
  }
}
