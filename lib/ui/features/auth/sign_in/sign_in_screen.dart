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

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final screenH = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Get.offAllNamed('/');
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenH - topPad - botPad,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 25,
                        right: 25,
                        top: 20,
                        bottom: bottomPad + 20,
                      ),
                      child: const IntrinsicHeight(
                        child: _SignInContent(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInContent extends StatelessWidget {
  const _SignInContent();

  InputDecoration _inputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: const BorderSide(color: Colors.transparent, width: 1),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SignInController>();

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Image.asset(
          "assets/images/tlogo_dark.png",
          height: 35,
          width: 145,
        ),
        const SizedBox(height: 30),
        const Text(
          "Welcome",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          "Back to",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          "Trapix",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCCFF00),
            height: 1,
          ),
        ),
        const Spacer(flex: 2),
        TextField(
          controller: controller.emailEditController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration("Email"),
        ),
        const SizedBox(height: 20),
        Obx(() {
          return TextField(
            controller: controller.passEditController,
            obscureText: !controller.isShowPassword.value,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
              "Password",
              suffix: IconButton(
                icon: Icon(
                  controller.isShowPassword.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: () {
                  controller.isShowPassword.value =
                      !controller.isShowPassword.value;
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
        const Spacer(flex: 3),
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
            color: Colors.transparent,
            child: InkWell(
              onTap: () => controller.isInPutDataValid(context),
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
        const SizedBox(height: 20),
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
        const SizedBox(height: 20),
      ],
    );
  }
}
