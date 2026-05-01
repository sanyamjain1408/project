import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart';
import 'package:tradexpro_flutter/ui/features/auth/social_login_view.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'sign_up_controller.dart';

const _green = Color(0xFFCCFF00);
const _inputBg = Color(0xFF1A1A1A);

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final _controller = Get.put(SignUpController());
  final RxBool _checkPrivacy = false.obs;
  final RxString _appName = "".obs;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _controller.phoneEditController.text =
        _controller.selectedPhone.value.phoneCode;
    getAppName().then((name) => _appName.value = name);
  }

  InputDecoration inputDec(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
      filled: true,
      fillColor: _inputBg,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.transparent)),
      suffixIcon: suffix,
    );
  }

  Widget gradientBtn(String label, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00E6FF), Color(0xFFCCFF00), Color(0xFF77D215)],
          stops: [0.0, 0.50, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
          ),
        ),
      ),
    );
  }

  Widget titleSection(String l1, String l2, String l3) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Image.asset("assets/images/tlogo_dark.png", height: 35, width: 145),
        const SizedBox(height: 30),
        Text(l1,
            style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1)),
        const SizedBox(height: 5),
        Text(l2,
            style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1)),
        const SizedBox(height: 5),
        Text(l3,
            style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: _green,
                height: 1)),
      ],
    );
  }

  void goToStep2() {
    final firstName = _controller.firstNameEditController.text.trim();
    final lastName = _controller.lastNameEditController.text.trim();
    final email = _controller.emailEditController.text.trim();

    if (firstName.isEmpty) {
      showToast("Please enter your first name");
      return;
    }
    if (lastName.isEmpty) {
      showToast("Please enter your last name");
      return;
    }
    if (email.isEmpty) {
      showToast("Please enter your email address");
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      showToast("Please enter a valid email address");
      return;
    }
    setState(() => _step = 1);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final screenH = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final availH = screenH - topPad - botPad;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_step == 1) {
            setState(() => _step = 0);
          } else {
            Get.off(() => const SignInPage());
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset("assets/images/bgimage.png",
                  fit: BoxFit.cover),
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
                      bottom: bottomPad + 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availH - 40),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _step == 0
                          ? _Step1(
                              key: const ValueKey(0),
                              parent: this,
                              availH: availH,
                            )
                          : _Step2(
                              key: const ValueKey(1),
                              parent: this,
                              availH: availH,
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

// ─── STEP 1 ──────────────────────────────────────────────────────────────────
class _Step1 extends StatelessWidget {
  final SignUpScreenState parent;
  final double availH;
  const _Step1({super.key, required this.parent, required this.availH});

  @override
  Widget build(BuildContext context) {
    final c = parent._controller;
    final gap = (availH * 0.06).clamp(16.0, 48.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        parent.titleSection("Create", "Your", "Account"),
        SizedBox(height: gap),

        // First Name
        TextField(
          controller: c.firstNameEditController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          decoration: parent.inputDec("First Name"),
        ),
        const SizedBox(height: 16),

        // Last Name
        TextField(
          controller: c.lastNameEditController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          decoration: parent.inputDec("Last Name"),
        ),
        const SizedBox(height: 16),

        // Optional label + Mobile
        const Text("Optional",
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 8),
        Obx(() => Container(
              decoration: BoxDecoration(
                  color: _inputBg,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  countryPickerView(
                    context,
                    c.selectedPhone.value,
                    (value) {
                      c.selectedPhone.value = value;
                      c.phoneEditController.text = value.phoneCode;
                    },
                    showPhoneCode: true,
                  ),
                  Expanded(
                    child: TextField(
                      controller: c.phoneEditController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: "Mobile Number",
                        hintStyle:
                            TextStyle(color: Colors.white54, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),

        // Email
        TextField(
          controller: c.emailEditController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: parent.inputDec("Email"),
        ),

        SizedBox(height: gap * 1.2),

        parent.gradientBtn("NEXT", parent.goToStep2),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Already have an account? ",
                style: TextStyle(color: Colors.white)),
            InkWell(
              onTap: () => Get.off(() => const SignInPage()),
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              child: const Text("Sign In",
                  style: TextStyle(
                      color: _green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── STEP 2 ──────────────────────────────────────────────────────────────────
class _Step2 extends StatelessWidget {
  final SignUpScreenState parent;
  final double availH;
  const _Step2({super.key, required this.parent, required this.availH});

  @override
  Widget build(BuildContext context) {
    final c = parent._controller;
    final gap = (availH * 0.06).clamp(16.0, 48.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back arrow
        GestureDetector(
          onTap: () => parent.setState(() => parent._step = 0),
          child: const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
        ),

        parent.titleSection("Secure", "Your", "Account"),
        SizedBox(height: gap),

        // Password
        Obx(() => TextField(
              controller: c.passEditController,
              obscureText: !c.isShowPassword.value,
              style: const TextStyle(color: Colors.white),
              decoration: parent.inputDec(
                "Password",
                suffix: IconButton(
                  icon: Icon(
                    c.isShowPassword.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () =>
                      c.isShowPassword.value = !c.isShowPassword.value,
                ),
              ),
            )),
        const SizedBox(height: 12),

        // Password strength
        _PasswordStrength(controller: c.passEditController),
        const SizedBox(height: 16),

        // Confirm Password
        Obx(() => TextField(
              controller: c.confirmPassEditController,
              obscureText: !c.isShowPassword.value,
              style: const TextStyle(color: Colors.white),
              decoration: parent.inputDec(
                "Confirm Password",
                suffix: IconButton(
                  icon: Icon(
                    c.isShowPassword.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () =>
                      c.isShowPassword.value = !c.isShowPassword.value,
                ),
              ),
            )),
        const SizedBox(height: 20),

        // Privacy checkbox
        Obx(() => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckBoxView(parent._checkPrivacy.value,
                    (v) => parent._checkPrivacy.value = v),
                Expanded(
                  child: textSpanWithAction(
                    "By creating an account, I agree to"
                        .trParams({"appName": parent._appName.value}),
                    "${"Privacy Police".tr}.",
                    maxLines: 3,
                    textAlign: TextAlign.start,
                    onTap: () =>
                        openUrlInBrowser(URLConstants.privacyLink),
                  ),
                ),
              ],
            )),

        SizedBox(height: gap * 1.2),

        parent.gradientBtn(
          "SIGN UP",
          () => c.isInPutDataValid(context, parent._checkPrivacy.value),
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
        const SizedBox(height: 20),
        const SocialLoginView(),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Password Strength ───────────────────────────────────────────────────────
class _PasswordStrength extends StatefulWidget {
  final TextEditingController controller;
  const _PasswordStrength({required this.controller});

  @override
  State<_PasswordStrength> createState() => _PasswordStrengthState();
}

class _PasswordStrengthState extends State<_PasswordStrength> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final p = widget.controller.text;
    final r1 = p.length >= 8;
    final r2 = p.contains(RegExp(r'[A-Z]')) && p.contains(RegExp(r'[a-z]'));
    final r3 = p.contains(RegExp(r'[0-9]'));
    final r4 = p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    final strength = [r1, r2, r3, r4].where((v) => v).length;

    Color barColor(int idx) {
      if (idx >= strength) return Colors.white12;
      if (strength == 1) return Colors.red;
      if (strength == 2) return Colors.orange;
      if (strength == 3) return Colors.yellow;
      return _green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
              4,
              (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: barColor(i),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
        ),
        const SizedBox(height: 12),
        _req("Is a minimum of 8 characters", r1),
        _req("Has uppercase and lowercase letters", r2),
        _req("Has number", r3),
        _req("Has special characters", r4),
      ],
    );
  }

  Widget _req(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            color: met ? _green : Colors.white38,
            size: 15,
          ),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  color: met ? Colors.white : Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
