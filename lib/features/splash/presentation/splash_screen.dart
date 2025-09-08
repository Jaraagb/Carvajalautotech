import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/navigation/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;

  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _navigateToNextScreen();
  }

  void _initializeAnimations() {
    // Controller para el logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controller para el texto
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Controller para el fondo
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animaciones
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _backgroundController.forward();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _logoController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 1000), () {
      _textController.forward();
    });
  }

  void _navigateToNextScreen() {
    Future.delayed(AppConstants.splashDuration, () {
      if (mounted) {
        AppRouter.navigateToLoginSelection(context);
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlack,
                  AppTheme.lightBlack.withOpacity(_backgroundAnimation.value),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, _backgroundAnimation.value],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo animado
                          AnimatedBuilder(
                            animation: _logoAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _logoAnimation.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryRed.withOpacity(
                                          0.5 * _logoAnimation.value,
                                        ),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.quiz_outlined,
                                    size: 60,
                                    color: AppTheme.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Texto del app animado
                          AnimatedBuilder(
                            animation: _textAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _textAnimation.value,
                                child: Transform.translate(
                                  offset: Offset(
                                    0,
                                    30 * (1 - _textAnimation.value),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        AppConstants.appName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: AppTheme.white,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2.0,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Sistema de Evaluación Inteligente',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.greyLight,
                                              letterSpacing: 1.0,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Loading indicator y versión
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Loading indicator animado
                        AnimatedBuilder(
                          animation: _textAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _textAnimation.value,
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(bottom: 24),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryRed,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        // Versión
                        AnimatedBuilder(
                          animation: _textAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _textAnimation.value * 0.7,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 32),
                                child: Text(
                                  'v${AppConstants.appVersion}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.greyMedium,
                                      ),
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
        },
      ),
    );
  }
}