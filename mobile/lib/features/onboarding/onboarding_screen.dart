import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      emoji: '🗺️',
      title: 'Travel.\nPlay.\nCollect.',
      subtitle: 'Turn every destination into a living game.',
    ),
    _Slide(
      emoji: '📍',
      title: 'Complete\nMissions.',
      subtitle: 'GPS check-ins, QR scans, food challenges — go beyond photos.',
    ),
    _Slide(
      emoji: '🏆',
      title: 'Earn Real\nRewards.',
      subtitle: 'Stamps, badges, discounts — unlock them as you explore.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (p) => setState(() => _page = p),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            _DotsRow(count: _slides.length, current: _page),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Get Started'),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text('I already have an account',
                        style: TextStyle(color: TrailColors.onSurfaceMuted)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.emoji, required this.title, required this.subtitle});
  final String emoji, title, subtitle;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(slide.emoji, style: const TextStyle(fontSize: 72))
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.6, 0.6)),
          const SizedBox(height: 32),
          Text(slide.title,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    height: 1.1,
                    color: TrailColors.onBackground,
                  ))
              .animate()
              .fadeIn(delay: 100.ms, duration: 500.ms)
              .slideX(begin: -0.2),
          const SizedBox(height: 16),
          Text(slide.subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: TrailColors.onSurfaceMuted,
                    height: 1.5,
                  ))
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms),
        ],
      ),
    );
  }
}

class _DotsRow extends StatelessWidget {
  const _DotsRow({required this.count, required this.current});
  final int count, current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: 250.ms,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? TrailColors.primary : TrailColors.onSurfaceMuted.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
