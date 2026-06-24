import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textProgressAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // 1. Text character progress animation (0.0 to 0.55 of overall progress)
    _textProgressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeInOut),
      ),
    );

    // 2. Logo scale & drop-down animation (0.50 to 0.95 of overall progress)
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.95, curve: Curves.easeOutBack),
      ),
    );

    // 3. Logo fade-in animation (0.50 to 0.80 of overall progress)
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.80, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _checkSessionAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Wait for the full animation plus some hover time
    await Future.delayed(const Duration(milliseconds: 3200));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // matched with login background
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double logoSlideOffset = -25.0 * (1.0 - _logoScaleAnimation.value);
            
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                Transform.translate(
                  offset: Offset(0, logoSlideOffset),
                  child: Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Opacity(
                      opacity: _logoFadeAnimation.value,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF2994A).withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(55),
                          child: Image.asset(
                            'assets/logo.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFFF2994A),
                                child: const Icon(
                                  Icons.restaurant_menu,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Spelling Text "PolyCanteen"
                _buildSpelledText(_textProgressAnimation.value),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpelledText(double progress) {
    const String text = "PolyCanteen";
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(text.length, (index) {
        // Stagger each letter's animation range inside the parent progress
        double start = (index / text.length) * 0.6;
        double end = start + 0.4;
        
        double charProgress = 0.0;
        if (progress >= start) {
          if (progress >= end) {
            charProgress = 1.0;
          } else {
            charProgress = (progress - start) / 0.4;
          }
        }
        
        double curvedValue = Curves.easeOutBack.transform(charProgress);
        
        // Two-tone branding: Poly (indices 0-3) in charcoal, Canteen (indices 4-10) in brand orange
        final bool isCanteen = index >= 4;
        final Color charColor = isCanteen ? const Color(0xFFF2994A) : const Color(0xFF1E232C);
        
        return Opacity(
          opacity: charProgress.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 16 * (1.0 - curvedValue)),
            child: Text(
              text[index],
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: charColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}
