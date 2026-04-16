import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Assuming these imports exist based on your previous code
import 'package:tradexpro_flutter/ui/features/auth/auth_widgets.dart'; 
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_up/sign_up_screen.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'forgot_password_controller.dart';

// ─────────────────────────────────────────────
// MAIN FORGOT PASSWORD PAGE
// ─────────────────────────────────────────────

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ForgotPasswordPageState createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _controller = Get.put(ForgotPasswordController());

  // --- BACK PRESS HANDLER ---
  Future<bool> _onWillPop() async {
    // SignInScreen par navigate karein
    Get.off(() => const SignInPage());
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black, // Base background
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // ── UPDATED: Background Image (Same as SignIn) ──
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
                    top: 20, // Top padding for scrolling
                  ),
                  // ── CENTER: Content ko screen ke beech mein laya ──
                  child: const Center(
                    child: _ForgotPasswordContent(),
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

// ─────────────────────────────────────────────
// SEPARATE CONTENT WIDGET
// ─────────────────────────────────────────────
class _ForgotPasswordContent extends StatelessWidget {
  const _ForgotPasswordContent();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForgotPasswordController>();

    return Column(
      mainAxisSize: MainAxisSize.min, // Content wrap karega, stretch nahi hoga
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        
        // Logo
        Image.asset(
          "assets/images/tlogo_dark.png",
          height: 35,
          width: 145,
        ),
        const SizedBox(height: 40),

        // Titles (Colors changed to White for contrast)
        const Text(
          "Welcome",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1, // Line height for better spacing
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          "Back to",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1, // Line height for better spacing
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          "Trapix",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB5F000),
            height: 1, // Line height for better spacing
          ),
        ),
        const SizedBox(height: 49),

        // Input Field
        TextField(
          controller: controller.emailEditController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "Email",
            hintStyle: const TextStyle(color: Colors.white, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF1A1A1A), // Dark input background
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
          ),
        ),

        const SizedBox(height: 20),

        // Warning Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle, // Circle look for icon
                color: Colors.transparent,
                border: Border.all(
                  color: const Color(0xFFB5F000),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.warning_amber_outlined,
                color: Color(0xFFB5F000),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "To protect your account, withdrawals and other outflows will be disabled for 24 hours after resetting your login password.",
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 90), // Space before button

        // Reset Password Button
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
             colors: [
                Color(0xFF00E6FF),
                Color(0xFFCCFF00),
                Color(0xFF77D215),
              ], // Updated to match theme
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
                  "RESET PASSWORD",
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
        
        const SizedBox(height: 180), // Extra bottom space
      ],
    );
  }
}