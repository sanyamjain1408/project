import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'change_password_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ChangePasswordScreenState createState() => ChangePasswordScreenState();
}

class ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _controller = Get.put(ChangePasswordController());

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  static const Color _primary = Color(0xFF111111);
  static const Color _secondary = Color(0xFF1A1A1A);
  static const Color _green = Color(0xFFCCFF00);
  static const _white = Color(0xFFFFFFFF);
  static const _dmSans = 'DMSans';

  @override
  void initState() {
    super.initState();

    // 🔥 LIVE UPDATE LISTENER
    _controller.newPassEditController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final password = _controller.newPassEditController.text;

    return Scaffold(
      backgroundColor: _primary,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.arrow_back, color: _white),
                ),
                const SizedBox(width: 20),
                const Text(
                  "Change Login Password",
                  style: TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                  ),
                ),
              ],
            ),

            vSpacer30(),

            // Warning Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _secondary, // Box BG
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: _green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "In order to protect your account, withdrawal, P2P selling and payments services might be disabled for 24 hours after you change your password.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        fontFamily: _dmSans,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            vSpacer30(),

            // Current Password
            _label("Current Password"),
            basicCustomTextField(
              controller: _controller.currentPassEditController,
              hint: "Current Password",
              isObscure: true,
              bgColor: _secondary,
              textColor: _white,
              hintColor: Colors.grey,
            ),

            vSpacer15(),

            // New Password
            _label("New Password"),
            basicCustomTextField(
              controller: _controller.newPassEditController,
              hint: "New Password",
              isObscure: !_isNewPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isNewPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
              ),
              bgColor: _secondary,
              textColor: _white,
              hintColor: Colors.grey,
            ),

            // 🔥 RULES
            _buildPasswordRules(password),

            vSpacer15(),

            // Confirm Password
            _label("Confirm Password"),
            basicCustomTextField(
              controller: _controller.confirmPassEditController,
              hint: "Confirm Password",
              isObscure: !_isConfirmPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              bgColor: _secondary,
              textColor: _white,
              hintColor: Colors.grey,
            ),

            SizedBox(height: 180,),

            buttonRoundedMain(
              text: "Confirm",
              onPress: () => _controller.isInPutDataValid(context),
              bgColor: _green,
              textColor: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Label Widget
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontFamily: _dmSans,
        ),
      ),
    );
  }

  // 🔥 PASSWORD RULES UI
  Widget _buildPasswordRules(String password) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        _buildRule(
          "Is a minimum 8 characters",
          password.isEmpty ? null : password.length >= 8,
        ),

        _buildRule(
          "Has uppercase & lowercase letters",
          password.isEmpty
              ? null
              : password.contains(RegExp(r'[a-z]')) &&
                    password.contains(RegExp(r'[A-Z]')),
        ),

        _buildRule(
          "Has number",
          password.isEmpty ? null : password.contains(RegExp(r'[0-9]')),
        ),

        _buildRule(
          "Has special character",
          password.isEmpty
              ? null
              : password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
        ),
      ],
    );
  }

  // 🔥 RULE ITEM
  Widget _buildRule(String text, bool? isValid) {
    Color color;

    if (isValid == null) {
      color = Colors.grey; // default
    } else {
      color = isValid ? _green : Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            isValid == null
                ? Icons.radio_button_unchecked
                : isValid
                ? Icons.check_circle
                : Icons.cancel,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
