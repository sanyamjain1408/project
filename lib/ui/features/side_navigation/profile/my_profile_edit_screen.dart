import 'dart:io';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import '../../../../data/models/user.dart';
import '../../../../utils/common_utils.dart';
import '../../../../helper/app_helper.dart';
import 'my_profile_controller.dart';

// ── FIGMA COLORS ─────────────────────────────────────────────────────────────
const _bg       = Color(0xFF121212);
const _cardBg   = Color(0xFF1E1E1E);
const _fieldBg  = Color(0xFF1A1A1A);
const _green    = Color(0xFFCCFF00);
const _white    = Color(0xFFFFFFFF);
const _grey     = Color(0xFF6B6B6B);
const _dmSans   = 'DMSans';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ProfileEditScreenState createState() => ProfileEditScreenState();
}

class ProfileEditScreenState extends State<ProfileEditScreen> {
  final _controller = Get.put(MyProfileController());
  User user = gUserRx.value;
  Rx<File> profileImage = File("").obs;
  Rx<Country> selectedPhone   = Country.parse("US").obs;
  Rx<Country> selectedCountry = Country.parse("US").obs;
  TextEditingController userNameController  = TextEditingController();
  TextEditingController emailController     = TextEditingController();
  TextEditingController phoneController     = TextEditingController();
  TextEditingController countryController   = TextEditingController();
  TextEditingController uidController       = TextEditingController();

  @override
  void initState() {
    super.initState();
    userNameController.text  = getName(user.firstName, user.lastName);
    emailController.text     = user.email ?? "";
    uidController.text       = user.id.toString();
    if (user.country.isValid) {
      try {
        selectedCountry.value   = Country.parse(user.country!);
        countryController.text  = selectedCountry.value.name;
      } catch (_) {}
    }
    _loadPhone();
  }

  void _loadPhone() async {
    if (user.phone.isValid) {
      try {
        var phone = user.phone!.contains("+") ? user.phone! : "+${user.phone!}";
        final info = await PhoneNumber.getRegionInfoFromPhoneNumber(phone);
        selectedPhone.value  = Country.parse(info.isoCode ?? "US");
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

                // ── USER NAME (read only) ─────────────────────────
                _fieldLabel("User Name"),
                const SizedBox(height: 6),
                _readOnlyField(userNameController),

                const SizedBox(height: 16),

                // ── EMAIL ─────────────────────────────────────────
                _fieldLabel("Email"),
                const SizedBox(height: 6),
                _editField(emailController, hint: "Email", keyboardType: TextInputType.emailAddress),

                const SizedBox(height: 16),

                // ── PHONE NUMBER ──────────────────────────────────
                _fieldLabel("Phone Number"),
                const SizedBox(height: 6),
                Obx(() => _phoneField()),

                const SizedBox(height: 16),

                // ── COUNTRY ───────────────────────────────────────
                _fieldLabel("Country"),
                const SizedBox(height: 6),
                Obx(() => _countryField()),

                const SizedBox(height: 16),

                // ── UID (read only) ───────────────────────────────
                _fieldLabel("UID Number"),
                const SizedBox(height: 6),
                _readOnlyField(uidController),

                const SizedBox(height: 30),
              ],
            ),
          ),

          // ── UPDATE BUTTON ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _checkAndUpdate,
                child: const Text(
                  "Update",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dmSans,
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
      style: const TextStyle(
        color: _grey,
        fontSize: 13,
        fontFamily: _dmSans,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // ── READ ONLY FIELD ───────────────────────────────────────────────────────
  Widget _readOnlyField(TextEditingController ctrl) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        ctrl.text,
        style: const TextStyle(
          color: _grey,
          fontSize: 15,
          fontFamily: _dmSans,
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
          hintStyle: const TextStyle(color: _grey, fontSize: 15, fontFamily: _dmSans),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  // ── PHONE FIELD ───────────────────────────────────────────────────────────
  Widget _phoneField() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => showCountryPicker(
              context: context,
              showPhoneCode: true,
              onSelect: (c) {
                selectedPhone.value  = c;
                phoneController.text = c.phoneCode;
              },
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Text(selectedPhone.value.flagEmoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: _grey, size: 20),
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
              style: const TextStyle(color: _white, fontSize: 15, fontFamily: _dmSans),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Phone number",
                hintStyle: TextStyle(color: _grey, fontSize: 15, fontFamily: _dmSans),
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
        onSelect: (c) {
          selectedCountry.value  = c;
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
            Text(selectedCountry.value.flagEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: _grey, size: 20),
            Container(width: 1, height: 28, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 12)),
            Expanded(
              child: Text(
                countryController.text.isNotEmpty ? countryController.text : "Country",
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
    updateUser.lastName  = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";

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