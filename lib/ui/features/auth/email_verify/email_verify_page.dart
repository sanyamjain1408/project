import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import '../sign_in/sign_in_screen.dart';
import 'email_verify_controller.dart';

const _green = Color(0xFFCCFF00);

class EmailVerifyPage extends StatefulWidget {
  final String registrationId;
  const EmailVerifyPage({super.key, required this.registrationId});

  @override
  EmailVerifyPageState createState() => EmailVerifyPageState();
}

class EmailVerifyPageState extends State<EmailVerifyPage> {
  final _controller = Get.put(EmailVerifyController());

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final availH = screenH - topPad - botPad;
    final gap = (availH * 0.06).clamp(16.0, 52.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Get.off(() => const SignInPage());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Background
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
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availH - 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back arrow
                        GestureDetector(
                          onTap: () => Get.off(() => const SignInPage()),
                          child: const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Icon(Icons.arrow_back,
                                color: Colors.white, size: 24),
                          ),
                        ),

                        // Logo
                        Image.asset("assets/images/tlogo_dark.png",
                            height: 35, width: 145),
                        const SizedBox(height: 30),

                        // Title
                        const Text("Verify",
                            style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1)),
                        const SizedBox(height: 5),
                        const Text("Your",
                            style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1)),
                        const SizedBox(height: 5),
                        const Text("Email",
                            style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: _green,
                                height: 1)),

                        SizedBox(height: gap),

                        // Subtitle
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                height: 1.5),
                            children: [
                              TextSpan(
                                  text:
                                      "${'Enter verification code which sent email'.tr} "),
                              TextSpan(
                                text: widget.registrationId,
                                style: const TextStyle(
                                    color: _green,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: gap * 0.8),

                        // OTP input
                        pinCodeView(
                            controller: _controller.codeEditController),

                        SizedBox(height: gap * 1.2),

                        // Verify button
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
                              onTap: () => _controller.isInPutDataValid(
                                  context, widget.registrationId),
                              borderRadius: BorderRadius.circular(12),
                              child: const Center(
                                child: Text(
                                  "VERIFY",
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

                        // Back to sign in link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Back to ",
                                style: TextStyle(color: Colors.white)),
                            InkWell(
                              onTap: () =>
                                  Get.off(() => const SignInPage()),
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              child: const Text(
                                "Sign In",
                                style: TextStyle(
                                    color: _green,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
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
