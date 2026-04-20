import 'dart:io';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import '../../../../data/models/user.dart';
import '../../../../utils/common_utils.dart';
import '../../../../helper/app_helper.dart';
import 'my_profile_controller.dart';

// ── FIGMA COLORS ─────────────────────────────────────────────────────────────
const _bg = Color(0xFF121212);
const _cardBg = Color(0xFF1E1E1E);
const _fieldBg = Color(0xFF1A1A1A);
const _green = Color(0xFFCCFF00);
const _white = Color(0xFFFFFFFF);
const _grey = Color(0xFF6B6B6B);
const _dmSans = 'DMSans';

const Color _primary = Color(0xFF111111);
const Color _secondary = Color(0xFF1A1A1A);
const Color _textSecondary = Color(0xFFCCFF00);

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ProfileEditScreenState createState() => ProfileEditScreenState();
}

class ProfileEditScreenState extends State<ProfileEditScreen> {
  final _controller = Get.put(MyProfileController());
  User user = gUserRx.value;
  Rx<File> profileImage = File("").obs;
  Rx<Country> selectedPhone = Country.parse("US").obs;
  Rx<Country> selectedCountry = Country.parse("US").obs;
  TextEditingController userNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController uidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userNameController.text = getName(user.firstName, user.lastName);
    emailController.text = user.email ?? "";
    uidController.text = user.id.toString();
    if (user.country.isValid) {
      try {
        selectedCountry.value = Country.parse(user.country!);
        countryController.text = selectedCountry.value.name;
      } catch (_) {}
    }
    _loadPhone();
  }

  void _loadPhone() async {
    if (user.phone.isValid) {
      try {
        var phone = user.phone!.contains("+") ? user.phone! : "+${user.phone!}";
        final info = await PhoneNumber.getRegionInfoFromPhoneNumber(phone);
        selectedPhone.value = Country.parse(info.isoCode ?? "US");
        phoneController.text = user.phone!;
      } catch (_) {
        phoneController.text = user.phone ?? "";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // ── SCROLLABLE CONTENT ────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              children: [
                SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),

                      SizedBox(width: 20),

                      const Text(
                        "Profile Update",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DMSans',
                          height: 1.25,
                        ),
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
                SizedBox(height: 10,),
                // ── USER NAME (read only) ─────────────────────────
                _fieldLabel("User Name"),
                const SizedBox(height: 5),
                _readOnlyField(userNameController),

                const SizedBox(height: 20),

                // ── EMAIL ─────────────────────────────────────────
                _fieldLabel("Email"),
                const SizedBox(height: 5),
                _editField(
                  emailController,
                  hint: "Email",
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                // ── PHONE NUMBER ──────────────────────────────────
                _fieldLabel("Phone Number"),
                const SizedBox(height: 5),
                Obx(() => _phoneField()),

                const SizedBox(height: 20),

                // ── COUNTRY ───────────────────────────────────────
                _fieldLabel("Country"),
                const SizedBox(height: 5),
                Obx(() => _countryField()),

                const SizedBox(height: 20),

                // ── UID (read only) ───────────────────────────────
                _fieldLabel("UID Number"),
                const SizedBox(height: 5),
                _readOnlyField(uidController),

                const SizedBox(height: 30),
              ],
            ),
          ),

          // ── UPDATE BUTTON ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: _checkAndUpdate,
                child: const Text(
                  "Update",
                  style: TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FIELD LABEL ───────────────────────────────────────────────────────────
  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 12,
        fontFamily: _dmSans,
        fontWeight: FontWeight.w400,
        height: 1.33, // line-height 16px
      ),
    );
  }

  // ── READ ONLY FIELD ───────────────────────────────────────────────────────
  Widget _readOnlyField(TextEditingController ctrl) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        ctrl.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: _dmSans,
          fontWeight: FontWeight.w400,
          height: 1.25,
        ),
      ),
    );
  }

  // ── EDITABLE FIELD ────────────────────────────────────────────────────────
  Widget _editField(
    TextEditingController ctrl, {
    String hint = "",
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: _white,
          fontSize: 15,
          fontFamily: _dmSans,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: _grey,
            fontSize: 15,
            fontFamily: _dmSans,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // ── PHONE FIELD ───────────────────────────────────────────────────────────
  Widget _phoneField() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: _secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => showCountryPicker(
              context: context,
              showPhoneCode: true,

              // 👇 YE ADD KARNA HAI (background fix)
              countryListTheme: CountryListThemeData(
                backgroundColor: _secondary,
                textStyle: TextStyle(color: Colors.white),
                borderRadius: BorderRadius.circular(20),
                inputDecoration: InputDecoration(
                  hintText: "Search",
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),

              onSelect: (c) {
                selectedPhone.value = c;

                // 👇 YE FIX (code show nahi ho raha tha)
                phoneController.text = "+${c.phoneCode}";
              },
            ),
            child: Container(
              color: _secondary,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Text(
                    selectedPhone.value.flagEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: _green,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 28, color: Colors.white12),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                color: _white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: _dmSans,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Phone number",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                  fontFamily: _dmSans,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ── COUNTRY FIELD ─────────────────────────────────────────────────────────
  Widget _countryField() {
    return GestureDetector(
      onTap: () => showCountryPicker(
        context: context,
        showPhoneCode: false,

        // 👇 SAME background fix
        countryListTheme: CountryListThemeData(
          backgroundColor: _secondary,
          textStyle: TextStyle(color: Colors.white),
          borderRadius: BorderRadius.circular(20),
        ),

        onSelect: (c) {
          selectedCountry.value = c;
          countryController.text = c.name;
        },
      ),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              selectedCountry.value.flagEmoji,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: _grey, size: 20),
            Container(
              width: 1,
              height: 28,
              color: Colors.white12,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            Expanded(
              child: Text(
                countryController.text.isNotEmpty
                    ? countryController.text
                    : "Country",
                style: TextStyle(
                  color: countryController.text.isNotEmpty ? _white : _grey,
                  fontSize: 15,
                  fontFamily: _dmSans,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UPDATE LOGIC ──────────────────────────────────────────────────────────
  void _checkAndUpdate() {
    User updateUser = user.createNewInstance();
    final nameParts = userNameController.text.trim().split(" ");
    updateUser.firstName = nameParts.isNotEmpty ? nameParts.first : "";
    updateUser.lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(" ")
        : "";

    if (phoneController.text.trim().isNotEmpty) {
      updateUser.phone = removeSpecialChar(phoneController.text.trim());
    }
    if (countryController.text.trim().isNotEmpty) {
      updateUser.country = selectedCountry.value.countryCode;
    }
    hideKeyboard(context: context);
    _controller.updateProfile(updateUser, profileImage.value);
  }
}
