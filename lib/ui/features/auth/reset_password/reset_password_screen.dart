import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/auth/forgot_password/forgot_password_page.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'reset_password_controller.dart';

// ─────────────────────────────────────────────
// MAIN RESET PASSWORD PAGE
// ─────────────────────────────────────────────

class ResetPasswordScreen extends StatefulWidget {
  final String registrationId;

  const ResetPasswordScreen({super.key, required this.registrationId});

  @override
  ResetPasswordScreenState createState() => ResetPasswordScreenState();
}

class ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _controller = Get.put(ResetPasswordController());
  
  // ─── UPDATE: List of 6 Controllers for OTP ───
  late List<TextEditingController> _otpControllers;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize 6 different controllers
    _otpControllers = List.generate(6, (index) => TextEditingController());
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  // --- BACK PRESS HANDLER ---
  Future<bool> _onWillPop() async {
    Get.off(() => const ForgotPasswordPage());
    return false;
  }
  
  // Function to scroll up when keyboard opens
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 25,
                    right: 25,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    top: 20,
                  ),
                  child: Center(
                    child: _ResetPasswordContent(
                      registrationId: widget.registrationId,
                      onPasswordFocus: _scrollToBottom,
                      otpControllers: _otpControllers, // Pass list here
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

// ─────────────────────────────────────────────
// SEPARATE CONTENT WIDGET
// ─────────────────────────────────────────────
class _ResetPasswordContent extends StatelessWidget {
  final String registrationId;
  final VoidCallback onPasswordFocus;
  final List<TextEditingController> otpControllers; // Accept list

  const _ResetPasswordContent({
    required this.registrationId, 
    required this.onPasswordFocus,
    required this.otpControllers,
  });

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

  InputDecoration _otpInputDecoration() {
    return InputDecoration(
      counterText: "",
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.transparent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _controller = Get.find<ResetPasswordController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
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

        // Titles
        const Text(
          "Welcome",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          "Back to",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          "Trapix",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB5F000),
          ),
        ),
        const SizedBox(height: 40),

        // Reset Code Label
        const Text(
          "Reset Code",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),

        // OTP Style Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              height: 50,
              child: TextField(
                // ─── FIX: Use specific controller from list ───
                controller: otpControllers[index],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: _otpInputDecoration(),
                onChanged: (value) {
                  // Logic: Agar value hai to next focus, agar khali hai to previous
                  if (value.isNotEmpty) {
                    if (index < 5) {
                      FocusScope.of(context).nextFocus();
                    }
                  } else {
                    if (index > 0) {
                      FocusScope.of(context).previousFocus();
                    }
                  }
                },
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // New Password Field
        Obx(() {
          return TextField(
            controller: _controller.passEditController,
            obscureText: !_controller.isShowPassword.value,
            style: const TextStyle(color: Colors.white),
            onTap: () => onPasswordFocus(),
            decoration: _inputDecoration(
              "New Password",
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

        const SizedBox(height: 20),

        // Confirm Password Field
        Obx(() {
          return TextField(
            controller: _controller.confirmPassEditController,
            obscureText: !_controller.isShowPassword.value,
            style: const TextStyle(color: Colors.white),
            onTap: () => onPasswordFocus(),
            decoration: _inputDecoration(
              "Confirm New Password",
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

        const SizedBox(height: 63),

        // Reset Button
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
              onTap: () {
                // ─── IMPORTANT: Combine OTPs before validating ───
                String fullOtpCode = "";
                for (var ctrl in otpControllers) {
                  fullOtpCode += ctrl.text;
                }
                
                // Set the combined code to the main controller
                _controller.codeEditController.text = fullOtpCode;
                
                // Call validation
                _controller.isInPutDataValid(context, registrationId);
              },
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
        
        const SizedBox(height: 60),
      ],
    );
  }
}