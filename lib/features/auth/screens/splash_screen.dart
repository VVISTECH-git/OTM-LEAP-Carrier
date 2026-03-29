import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:leapcarrier/core/services/session_service.dart';
import 'package:leapcarrier/core/theme/leap_theme.dart';
import 'package:leapcarrier/features/auth/screens/login_screen.dart';
import 'package:leapcarrier/features/home/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _tagCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _bgAnim;
  late Animation<double> _logoFade;
  late Animation<Offset>  _logoSlide;
  late Animation<double> _tagFade;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _bgCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _logoCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _tagCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _bgAnim    = CurvedAnimation(parent: _bgCtrl,   curve: Curves.easeInOut);
    _logoFade  = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));
    _tagFade   = CurvedAnimation(parent: _tagCtrl,  curve: Curves.easeOut);
    _pulse     = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _bgCtrl.forward().then((_) {
      _logoCtrl.forward().then((_) {
        _tagCtrl.forward();
      });
    });

    Future.delayed(const Duration(milliseconds: 2800), _checkSession);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _tagCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    if (!mounted) return;
    final hasSession = await SessionService.instance.isLoggedIn;
    final isExpired  = hasSession
        ? await SessionService.instance.isSessionExpired
        : false;

    // Clear stale token if the session has exceeded the idle TTL
    if (hasSession && isExpired) {
      await SessionService.instance.softLogout();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            (hasSession && !isExpired) ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ← was CarrierThemeProvider — now LeapThemeProvider
    final primary = context.watch<LeapThemeProvider>().theme.primary;
    final size    = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(children: [

          // ── Layer 1: Animated route grid ──────────────────────────────
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _RouteGridPainter(
                  progress: _bgAnim.value, primary: primary),
            ),
          ),

          // ── Layer 2: Radial glow ───────────────────────────────────────
          AnimatedBuilder(
            animation: _logoFade,
            builder: (_, __) => Positioned(
              left: size.width / 2 - 140,
              top:  size.height / 2 - 220,
              child: Opacity(
                opacity: _logoFade.value * 0.45,
                child: Container(
                  width: 280, height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      primary.withValues(alpha: 0.35),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 3: Main content ──────────────────────────────────────
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // Icon ring with pulse
              SlideTransition(
                position: _logoSlide,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Stack(alignment: Alignment.center, children: [
                      // Outer pulse ring
                      Container(
                        width: 104 + (18 * _pulse.value),
                        height: 104 + (18 * _pulse.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primary.withValues(alpha: 0.12 * _pulse.value),
                            width: 1.5,
                          ),
                        ),
                      ),
                      // Static ring
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      // Carrier icon — office building
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E1E1E),
                          boxShadow: [BoxShadow(
                            color: primary.withValues(alpha: 0.28),
                            blurRadius: 24, spreadRadius: 2,
                          )],
                        ),
                        child: Center(
                          child: _CarrierIcon(color: primary),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Wordmark
              FadeTransition(
                opacity: _logoFade,
                child: SlideTransition(
                  position: _logoSlide,
                  child: Column(children: [
                    const Text('LEAP',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 52, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 10, height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 28, height: 1.5, color: primary),
                      const SizedBox(width: 10),
                      Text('CARRIER',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: primary, letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 28, height: 1.5, color: primary),
                    ]),
                  ]),
                ),
              ),

              const SizedBox(height: 32),

              // Tagline + Oracle badge
              FadeTransition(
                opacity: _tagFade,
                child: Column(children: [
                  Text('Service Provider Portal',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans', fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.38),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 7, height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: LeapPlatform.oracleOrange,  // ← was hardcoded 0xFFF97316
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Powered by Oracle OTM',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans', fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.45),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),

          // ── Layer 4: Progress bar ──────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: FadeTransition(
              opacity: _tagFade,
              child: AnimatedBuilder(
                animation: _bgCtrl,
                builder: (_, __) => LinearProgressIndicator(
                  value: _bgCtrl.value,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation(primary),
                  minHeight: 2,
                ),
              ),
            ),
          ),

        ]),
      ),
    );
  }
}

// ── Carrier icon — office building ────────────────────────────────────────────
class _CarrierIcon extends StatelessWidget {
  const _CarrierIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(36, 36),
      painter: _CarrierIconPainter(color: color),
    );
  }
}

class _CarrierIconPainter extends CustomPainter {
  final Color color;
  const _CarrierIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    final building = Path()
      ..moveTo(w * 0.1, h * 0.92)
      ..lineTo(w * 0.1, h * 0.22)
      ..lineTo(w * 0.9, h * 0.22)
      ..lineTo(w * 0.9, h * 0.92);
    canvas.drawPath(building, paint);

    canvas.drawLine(Offset(w * 0.05, h * 0.92), Offset(w * 0.95, h * 0.92), paint);
    canvas.drawLine(Offset(w * 0.1,  h * 0.22), Offset(w * 0.9,  h * 0.22), paint);

    final winPaint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      final x = w * (0.2 + i * 0.22);
      canvas.drawRect(Rect.fromLTWH(x, h * 0.33, w * 0.14, h * 0.14), winPaint);
    }
    for (int i = 0; i < 3; i++) {
      final x = w * (0.2 + i * 0.22);
      canvas.drawRect(Rect.fromLTWH(x, h * 0.53, w * 0.14, h * 0.14), winPaint);
    }

    canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.72, w * 0.24, h * 0.20), paint);
    canvas.drawLine(Offset(w * 0.5, h * 0.22), Offset(w * 0.5, h * 0.08), paint);

    final flagPath = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..lineTo(w * 0.72, h * 0.12)
      ..lineTo(w * 0.5, h * 0.17);
    canvas.drawPath(flagPath, paint);
  }

  @override
  bool shouldRepaint(_CarrierIconPainter old) => old.color != color;
}

// ── Route grid painter ────────────────────────────────────────────────────────
class _RouteGridPainter extends CustomPainter {
  final double progress;
  final Color  primary;
  _RouteGridPainter({required this.progress, required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    // Guard: skip painting entirely if the canvas has no area.
    // This happens during Flutter's initial warm-up frame where constraints
    // haven't resolved yet (size is 0x0), causing path.computeMetrics() to
    // return an empty iterable and .first to throw "Bad state: No element".
    if (size.width <= 0 || size.height <= 0) return;

    final rand      = math.Random(13);
    final linePaint = Paint()..strokeWidth = 1.0..style = PaintingStyle.stroke;

    for (int i = 0; i < 20; i++) {
      final sx    = rand.nextDouble() * size.width;
      final sy    = rand.nextDouble() * size.height;
      final ex    = rand.nextDouble() * size.width;
      final ey    = rand.nextDouble() * size.height;
      final alpha = (0.025 + rand.nextDouble() * 0.055) * progress;
      linePaint.color = primary.withValues(alpha: alpha);

      final mx   = rand.nextBool() ? ex : sx;
      final my   = rand.nextBool() ? sy : ey;
      final path = Path()
        ..moveTo(sx, sy)
        ..lineTo(mx, my)
        ..lineTo(ex, ey);

      // Guard: computeMetrics() can return empty if the path has zero length
      // (e.g. all points coincide). Using firstOrNull avoids the crash.
      final metricsList = path.computeMetrics().toList();
      if (metricsList.isEmpty) continue;
      final metrics = metricsList.first;

      canvas.drawPath(metrics.extractPath(0, metrics.length * progress), linePaint);

      if (progress > 0.65) {
        canvas.drawCircle(Offset(ex, ey), 1.8,
            Paint()..color = primary.withValues(alpha: alpha * 2.5));
      }
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.018 * progress)
      ..strokeWidth = 0.5;
    const step = 42.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_RouteGridPainter old) =>
      old.progress != progress || old.primary != primary;
}