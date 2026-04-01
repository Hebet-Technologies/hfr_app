import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/routes/routes_name.dart';
import '../../view_model/providers.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authViewModel = ref.read(authViewModelProvider.notifier);
    final isLoggedIn = await authViewModel.checkLoginStatus();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, RoutesName.home);
    } else {
      Navigator.pushReplacementNamed(context, RoutesName.intro);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final topInset = MediaQuery.paddingOf(context).top;
          final bottomImageHeight = height * 0.35;
          final contentTop = topInset + (height * 0.085);
          final fadeHeight = bottomImageHeight * 0.58;

          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomImageHeight,
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Color(0xFFF9FBFE)),
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0xD9FFFFFF),
                          Color(0xFFFFFFFF),
                          Color(0xFFFFFFFF),
                        ],
                        stops: [0.0, 0.26, 0.52, 1.0],
                      ).createShader(bounds);
                    },
                    child: Image.asset(
                      'assets/images/background_2.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomImageHeight - (fadeHeight * 0.34),
                height: fadeHeight,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          Colors.white.withValues(alpha: 0.96),
                          Colors.white.withValues(alpha: 0.72),
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.22, 0.46, 0.78, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomImageHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0.03),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.24, 0.72],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: contentTop,
                left: 24,
                right: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 128,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'HRH Staff Portal',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 31,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2D3654),
                        letterSpacing: -0.5,
                        height: 1.04,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Human Resource for Health\nMinistry of Health - Zanzibar',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.55,
                        color: const Color(0xFF97A6BF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
