import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/features/root/root_screen.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  OnBoardingScreenState createState() => OnBoardingScreenState();
}

class OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _goNext() {
    if (_currentPage == 0) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnBoarding();
    }
  }

  void _finishOnBoarding() {
    GetStorage().write(PreferenceKey.isOnBoardingDone, true);
    Get.off(
      () => const RootScreen(),
      transition: Transition.leftToRightWithFade,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (p) => setState(() => _currentPage = p),
        children: [
          _Screen1(onNext: _goNext),
          _Screen2(onNext: _goNext),
        ],
      ),
    );
  }
}

// ─── SCREEN 1 ────────────────────────────────────────────────────────────────

class _Screen1 extends StatelessWidget {
  final VoidCallback onNext;
  const _Screen1({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        Image.asset('assets/images/bgimage.png', fit: BoxFit.cover),

        SafeArea(
          child: Column(
            children: [
              // Logo top-left
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset('assets/images/tlogo.png', height: 35),
                ),
              ),

              // Center image (start.png)
              Expanded(
                child: Center(
                  child: Transform.translate(
                offset: const Offset(0, 30),
                child: Padding(
                    padding: const EdgeInsets.only(
                      left: 0,
                      right: 0,
                      top: 0,
                    ),
                    child: Image.asset(
                      'assets/images/start.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  )
                ),
              ),

              // Bottom text + button
              Transform.translate(
                offset: const Offset(-10, 0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                          children: [
                            TextSpan(
                              text: 'Own Your\nMoney,\nShape ',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'Your Life.',
                              style: TextStyle(color: Color(0xFFCCFF00)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        'From saving smart to spending wise,\nyour financial goals begin to rise.',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // GET STARTED NOW button
              _GetStartedButton(onTap: onNext),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── SCREEN 2 ────────────────────────────────────────────────────────────────

class _Screen2 extends StatefulWidget {
  final VoidCallback onNext;
  const _Screen2({required this.onNext});

  @override
  State<_Screen2> createState() => _Screen2State();
}

class _Screen2State extends State<_Screen2> {
  // Row 1 & 3: left → right, Row 2: right → left
  late ScrollController _ctrl1;
  late ScrollController _ctrl2;
  late ScrollController _ctrl3;
  Timer? _timer;

  static const double _rowHeight = 54;
  static const double _speed = 0.6; // px per tick

  @override
  void initState() {
    super.initState();
    _ctrl1 = ScrollController(initialScrollOffset: 0);
    _ctrl2 = ScrollController(initialScrollOffset: 1000);
    _ctrl3 = ScrollController(initialScrollOffset: 0);

    // Start after first frame so maxScrollExtent is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  void _startScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _scrollRow(_ctrl1, forward: true);
      _scrollRow(_ctrl2, forward: false);
      _scrollRow(_ctrl3, forward: true);
    });
  }

  void _scrollRow(ScrollController ctrl, {required bool forward}) {
    if (!ctrl.hasClients) return;
    final max = ctrl.position.maxScrollExtent;
    if (max <= 0) return;
    double next = ctrl.offset + (forward ? _speed : -_speed);
    if (next >= max) next = 0;
    if (next <= 0) next = max;
    ctrl.jumpTo(next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl1.dispose();
    _ctrl2.dispose();
    _ctrl3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        
        Image.asset('assets/images/start2.png', fit: BoxFit.cover),

        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset('assets/images/tlogo.png', height: 35),
                ),
              ),

              const SizedBox(height: 40),

              // Title
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Join To\nBuilding',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const Text(
                      'The Future.',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFCCFF00),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 20),
                     Text(
                      'Empowering You to Invest, Trade,\nand Grow in the Next Generation of\nDigital Finance.',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 3 scrolling rows
              _InfiniteRow(
                controller: _ctrl1,
                imagePath: 'assets/images/row1.png',
                height: _rowHeight,
              ),
              const SizedBox(height: 20),
              _InfiniteRow(
                controller: _ctrl2,
                imagePath: 'assets/images/row2.png',
                height: _rowHeight,
              ),
              const SizedBox(height: 20),
              _InfiniteRow(
                controller: _ctrl3,
                imagePath: 'assets/images/row3.png',
                height: _rowHeight,
              ),

              const Spacer(),

              _GetStartedButton(onTap: widget.onNext),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── INFINITE SCROLLING ROW ───────────────────────────────────────────────────

class _InfiniteRow extends StatelessWidget {
  final ScrollController controller;
  final String imagePath;
  final double height;

  const _InfiniteRow({
    required this.controller,
    required this.imagePath,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Repeat image 3 times to enable seamless loop
    return SizedBox(
      height: height,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 20, // enough copies
        itemBuilder: (ctx, i) =>
            Image.asset(imagePath, height: height, fit: BoxFit.fitHeight),
      ),
    );
  }
}

// ─── GET STARTED BUTTON ───────────────────────────────────────────────────────

class _GetStartedButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GetStartedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        color: const Color(0xFFCCFF00),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'GET STARTED NOW',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.arrow_forward, color: Colors.black, size: 22),
          ],
        ),
      ),
    );
  }
}
