import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/auth/forgot_password/forgot_password_page.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_up/sign_up_screen.dart';
import 'package:tradexpro_flutter/ui/features/auth/social_login_view.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'sign_in_controller.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final _controller = Get.put(SignInController());

  // ─── BACK PRESS LOGIC ───
  Future<bool> _onWillPop() async {
    // Landing Screen par wapas jayega (Route name '/' hai)
    Get.offAllNamed('/'); 
    // Ya specific page: Get.offAll(() => LandingPage());
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                "assets/images/bgimage.png",
                fit: BoxFit.cover,
              ),
            ),

            SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 25,
                    right: 25,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    top: 20,
                  ),
                  child: const Center(
                    child: _SignInContent(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to access decoration easily or define it here if preferred
  // But since we moved content to separate widget, let's keep decoration logic clean.
}

class _SignInContent extends StatelessWidget {
  const _SignInContent();

  // ─── INPUT DECORATION HELPER ───
  InputDecoration _inputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Colors.transparent, width: 1),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _controller = Get.find<SignInController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Image.asset(
          "assets/images/tlogo_dark.png",
          height: 35,
          width: 145,
        ),
        const SizedBox(height: 40),
        const Text(
          "Welcome",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1,
          ),
        ),
        SizedBox(height: 5),
        const Text(
          "Back to",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1,
          ),
        ),
       SizedBox(height: 5),
        const Text(
          "Trapix",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCCFF00),
            height: 1,
          ),
        ),
        const SizedBox(height: 49),
        TextField(
          controller: _controller.emailEditController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration("Email"),
        ),
        const SizedBox(height: 20),
        Obx(() {
          return TextField(
            controller: _controller.passEditController,
            obscureText: !_controller.isShowPassword.value,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
              "Password",
              suffix: IconButton(
                icon: Icon(
                  _controller.isShowPassword.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: () {
                  _controller.isShowPassword.value =
                      !_controller.isShowPassword.value;
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () => Get.off(() => const ForgotPasswordPage()),
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: const Text(
              "Forgot Password?",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 63),
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00E6FF),
                Color(0xFFCCFF00),
                Color(0xFF77D215),
              ],
              stops: [0.0, 0.50, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent, // FIXED: Removed space between Colors and transparent
            child: InkWell(
              onTap: () => _controller.isInPutDataValid(context),
              borderRadius: BorderRadius.circular(12),
              child: const Center(
                child: Text(
                  "SIGN IN",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20), // FIXED: Removed 'par'
        Row(
          children: const [
            Expanded(child: Divider(color: Colors.white24, thickness: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text("Or", style: TextStyle(color: Colors.white54)),
            ),
            Expanded(child: Divider(color: Colors.white24, thickness: 1)),
          ],
        ),
        vSpacer20(),
        const SocialLoginView(),
        vSpacer20(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(color: Colors.white),
            ),
            InkWell(
              onTap: () => Get.off(() => const SignUpScreen()),
              child: const Text(
                "Sign up",
                style: TextStyle(
                  color: Color(0xFFCCFF00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}