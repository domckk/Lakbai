import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  // Drives the fade-out before we navigate away
  late final AnimationController _exitCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _exitFade = Tween<double>(begin: 1, end: 0)
      .animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInCubic));

  @override
  void initState() {
    super.initState();
    // Hide status bar for a true full-screen splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Trigger the exit after enter animations have finished playing
    Future.delayed(const Duration(milliseconds: 2400), _exit);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _exitCtrl.dispose();
    super.dispose();
  }

  Future<void> _exit() async {
    if (!mounted) return;
    await _exitCtrl.forward();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _exitFade,
      child: Scaffold(
        backgroundColor: TrailColors.brown,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // ── App icon — springs in from a tiny dot ──────────────────
              Image.asset(
                'assets/images/icon.png',
                width: 150,
                height: 150,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.explore_rounded,
                  size: 120,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.1, 0.1),
                    end: const Offset(1, 1),
                    duration: 750.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 250.ms)
                  // Subtle shimmer after the spring settles
                  .then(delay: 200.ms)
                  .shimmer(
                    duration: 900.ms,
                    color: Colors.white.withValues(alpha: 0.25),
                    angle: 0.3,
                  ),

              const SizedBox(height: 28),

              // ── Tagline ────────────────────────────────────────────────
              Text(
                'Discover. Explore. Conquer.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              )
                  .animate()
                  .fadeIn(delay: 550.ms, duration: 400.ms),

              const Spacer(),

              // ── Loading dots at the bottom ─────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 52),
                child: _PulsingDots(),
              )
                  .animate()
                  .fadeIn(delay: 900.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Three softly pulsing dots to hint that the app is loading ─────────────

class _PulsingDots extends StatefulWidget {
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            // Stagger each dot by 200ms
            final offset = (i * 0.25).clamp(0.0, 1.0);
            final t = ((_ctrl.value - offset).abs() % 1.0);
            final opacity = 0.3 + 0.7 * (1 - t);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity.clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
