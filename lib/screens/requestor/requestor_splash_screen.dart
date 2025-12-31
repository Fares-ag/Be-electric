import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class RequestorSplashScreen extends StatefulWidget {
  const RequestorSplashScreen({super.key});

  @override
  State<RequestorSplashScreen> createState() => _RequestorSplashScreenState();
}

class _RequestorSplashScreenState extends State<RequestorSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  int _currentScreen = 0;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _startSequence();
  }

  void _startSequence() {
    // Start logo animation
    _logoController.forward();

    // Total sequence: 3 seconds
    // Screen 1: Logo fade in (0.8s) + hold (0.2s) = 1s
    // Screen 2: Logo (0.5s)
    // Screen 3: Logo (0.5s)
    // Screen 4: EV Charging Image with logo overlay (1s)
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _currentScreen = 1);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _currentScreen = 2);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() => _currentScreen = 3);
                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (mounted) {
                    _navigateToMain();
                  }
                });
              }
            });
          }
        });
      }
    });
  }

  void _navigateToMain() {
    if (mounted) {
      try {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      } catch (e) {
        debugPrint('Navigation error: $e');
        // If navigation fails, try again after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            try {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            } catch (e2) {
              debugPrint('Retry navigation error: $e2');
            }
          }
        });
      }
    }
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoFadeAnimation,
      child: ScaleTransition(
        scale: _logoScaleAnimation,
        child: Image.asset(
          'assets/images/beElectricWhiteLogo.png',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.bolt,
              size: 100,
              color: Colors.white,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoScreen() {
    return Container(
      key: ValueKey('logo_$_currentScreen'),
      color: const Color(0xFF002911),
      child: Center(
        child: _buildLogo(),
      ),
    );
  }

  Widget _buildImageScreen() {
    return Container(
      key: const ValueKey('image'),
      color: const Color(0xFF002911),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/BeelectricPearlImg.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF002911),
                child: const Center(
                  child: Icon(
                    Icons.electric_car,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          // Logo overlay (faded in)
          Center(
            child: _buildLogo(),
          ),
          // Optional overlay for better logo visibility
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.transparent,
                  const Color(0xFF002911).withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;

    if (_currentScreen < 3) {
      // Screens 0, 1, 2: Logo on dark green
      currentScreen = _buildLogoScreen();
    } else {
      // Screen 3: EV Charging Image with logo overlay
      currentScreen = _buildImageScreen();
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: currentScreen,
      ),
    );
  }
}
