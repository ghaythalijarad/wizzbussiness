import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../utils/responsive_helper.dart';

class SplashScreen extends StatefulWidget {
  final Function()? onSplashComplete;
  const SplashScreen({Key? key, this.onSplashComplete}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _textController;
  late AnimationController _particleController;
  late AnimationController _waveController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _mainController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _particleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _waveController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_mainController);
    _textSlideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _particleAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_particleController);
    _waveAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_waveController);
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    _waveController.repeat();
    _particleController.repeat();
    await Future.delayed(const Duration(milliseconds: 500));
    _mainController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (widget.onSplashComplete != null) widget.onSplashComplete!();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF3F51B5),
              Color(0xFF2196F3),
              Color(0xFF00E5FF),
            ],
          ),
        ),
        child: Stack(
          children: [
            ...List.generate(3, (index) => _buildAnimatedWave(index)),
            ...List.generate(12, (index) => _buildFloatingParticle(index)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      height: ResponsiveHelper.isTablet(context) ||
                              ResponsiveHelper.isDesktop(context)
                          ? 120
                          : 100),
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      final isTabletOrDesktop =
                          ResponsiveHelper.isTablet(context) ||
                              ResponsiveHelper.isDesktop(context);
                      return Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF00E5FF),
                                Color(0xFFFFFFFF),
                                Color(0xFF00E5FF),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              loc.wizzBusiness,
                              style: TextStyle(
                                fontSize: isTabletOrDesktop ? 48 : 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: isTabletOrDesktop ? 3 : 2,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                      height: ResponsiveHelper.isTablet(context) ||
                              ResponsiveHelper.isDesktop(context)
                          ? 24
                          : 16),
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      final isTabletOrDesktop =
                          ResponsiveHelper.isTablet(context) ||
                              ResponsiveHelper.isDesktop(context);
                      return Opacity(
                        opacity: _opacityAnimation.value,
                        child: Text(
                          loc.businessManagement,
                          style: TextStyle(
                            fontSize: isTabletOrDesktop ? 22 : 18,
                            color: const Color(0xFF00E5FF),
                            letterSpacing: isTabletOrDesktop ? 4 : 3,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedWave(int index) {
    final delay = index * 0.3;
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Positioned(
          bottom: -100 + (index * 50),
          left: -200,
          right: -200,
          child: Transform.translate(
            offset: Offset(
              math.sin((_waveAnimation.value + delay) * 2 * math.pi) * 50,
              math.cos((_waveAnimation.value + delay) * 2 * math.pi) * 20,
            ),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.1 - index * 0.03),
                    const Color(0xFF00E5FF).withOpacity(0.05 - index * 0.01),
                  ],
                ),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingParticle(int index) {
    final delay = index * 0.1;
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        return Positioned(
          left: (screenWidth * 0.1) +
              (screenWidth * 0.8 * ((index % 4) / 3)) +
              math.sin((_particleAnimation.value + delay) * 2 * math.pi) * 30,
          top: (screenHeight * 0.1) +
              (screenHeight * 0.8 * ((index % 3) / 2)) +
              math.cos((_particleAnimation.value + delay) * 2 * math.pi) * 40,
          child: Container(
            width: 8 + (index % 3) * 4,
            height: 8 + (index % 3) * 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E5FF).withOpacity(0.8),
                  const Color(0xFF2196F3).withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
