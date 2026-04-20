import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/extensions.dart';
import '../../../../../data/models/bank_data.dart';
import '../../../../../data/models/dynamic_form.dart';
import 'user_bank_controller.dart';

const _bg = Color(0xFF111111);
const _fieldBg = Color(0xFF1A1A1A);
const _green = Color(0xFFCCFF00);
const _white = Color(0xFFFFFFFF);
const _grey = Color(0x80FFFFFF);
const _dmSans = 'DMSans';
const Color _primary = Color(0xFF111111);
const Color _secondary = Color(0xFF1A1A1A);
const Color _textSecondary = Color(0xFFCCFF00);

class BankInputPage extends StatefulWidget {
  const BankInputPage({super.key, this.preBank});
  final DynamicBank? preBank;

  @override
  State<BankInputPage> createState() => _BankInputPageState();
}

class _BankInputPageState extends State<BankInputPage> {
  final _controller = Get.find<UserBankController>();

  // Hardcoded field controllers
  final _accountNumberCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  // Error strings (reactive)
  final _accountNumberError = RxString('');
  final _accountHolderError = RxString('');
  final _bankNameError = RxString('');
  final _ifscError = RxString('');

  @override
  void initState() {
    super.initState();
    if (widget.preBank != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.getBankDetails(widget.preBank?.id ?? 0, _populateFields);
      });
    }
  }

  /// Fill fields when editing an existing bank
  void _populateFields(DynamicBank? preBank) {
    final items = preBank?.bank ?? {};
    _accountNumberCtrl.text = items['account_number']?.value ?? '';
    _accountHolderCtrl.text = items['account_holder']?.value ?? '';
    _bankNameCtrl.text = items['bank_name']?.value ?? '';
    _ifscCtrl.text = items['ifsc_code']?.value ?? '';
  }

  @override
  void dispose() {
    _accountNumberCtrl.dispose();
    _accountHolderCtrl.dispose();
    _bankNameCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.preBank != null;
    final btnTitle = isEdit ? "Update Bank" : "Save Bank";

    return Scaffold(
      backgroundColor: _primary,

      body: Column(
        children: [
          SizedBox(height: 30),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              children: [
                Container(
                  color: Colors.transparent,

                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(
                          Icons.arrow_back,
                          color: _white,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 20,),
                      Text(
                        isEdit ? "Bank Details" : "Add Bank",
                        style: const TextStyle(
                          color: _white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: _dmSans,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20,),

                // ── ACCOUNT NUMBER ──────────────────────────────────
                _buildField(
                  label: "Account Number",
                  hint: "Enter account number",
                  controller: _accountNumberCtrl,
                  error: _accountNumberError,
                  keyboardType: TextInputType.number,
                ),

                // ── ACCOUNT HOLDER NAME ─────────────────────────────
                _buildField(
                  label: "Account Holder Name",
                  hint: "Enter account holder name",
                  controller: _accountHolderCtrl,
                  error: _accountHolderError,
                ),

                // ── BANK NAME ───────────────────────────────────────
                _buildField(
                  label: "Bank Name",
                  hint: "Enter bank name",
                  controller: _bankNameCtrl,
                  error: _bankNameError,
                ),

                // ── IFSC CODE ───────────────────────────────────────
                _buildField(
                  label: "IFSC Code",
                  hint: "Enter IFSC code (e.g. SBIN0001234)",
                  controller: _ifscCtrl,
                  error: _ifscError,
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ),
          ),

          // ── BOTTOM BUTTONS ──────────────────────────────────────────

          // Remove Bank (edit mode only)
          if (isEdit)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 0.5),
                    backgroundColor: _secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _confirmDelete,
                  child: const Text(
                    "Remove Bank Account",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontFamily: _dmSans,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          // Save / Update button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
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
                onPressed: _onSavePressed,
                child: Text(
                  btnTitle,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
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

  // ── Reusable field builder ────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required RxString error,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 6),
          Obx(
            () => Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _secondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: error.value.isNotEmpty
                      ? Colors.red.withOpacity(0.5)
                      : Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                textCapitalization: textCapitalization,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: _dmSans,
                  height: 1.25,
                ),
                onChanged: (_) {
                  if (error.value.isNotEmpty) error.value = '';
                },
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
            ),
          ),
          Obx(
            () => error.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      error.value,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontFamily: _dmSans,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      color: Colors.white.withOpacity(0.5),
      fontSize: 12,
      fontWeight: FontWeight.w400,
      fontFamily: _dmSans,
    ),
  );

  // ── Validation ────────────────────────────────────────────────────────
  bool _validate() {
    bool ok = true;

    final accountNumber = _accountNumberCtrl.text.trim();
    final accountHolder = _accountHolderCtrl.text.trim();
    final bankName = _bankNameCtrl.text.trim();
    final ifsc = _ifscCtrl.text.trim();

    if (accountNumber.isEmpty) {
      _accountNumberError.value = 'Account number is required';
      ok = false;
    } else if (!RegExp(r'^\d{9,18}$').hasMatch(accountNumber)) {
      _accountNumberError.value = 'Enter a valid account number (9–18 digits)';
      ok = false;
    } else {
      _accountNumberError.value = '';
    }

    if (accountHolder.isEmpty) {
      _accountHolderError.value = 'Account holder name is required';
      ok = false;
    } else {
      _accountHolderError.value = '';
    }

    if (bankName.isEmpty) {
      _bankNameError.value = 'Bank name is required';
      ok = false;
    } else {
      _bankNameError.value = '';
    }

    if (ifsc.isEmpty) {
      _ifscError.value = 'IFSC code is required';
      ok = false;
    } else if (!RegExp(
      r'^[A-Z]{4}0[A-Z0-9]{6}$',
    ).hasMatch(ifsc.toUpperCase())) {
      _ifscError.value = 'Enter a valid IFSC code (e.g. SBIN0001234)';
      ok = false;
    } else {
      _ifscError.value = '';
    }

    return ok;
  }

  void _onSavePressed() {
    if (!_validate()) return;
    hideKeyboard();
    _controller.userBankSave(
      accountNumber: _accountNumberCtrl.text.trim(),
      accountHolder: _accountHolderCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim().toUpperCase(),
      bankId: widget.preBank?.id,
    );
  }

  // ── Delete confirmation dialog ────────────────────────────────────────
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _fieldBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          "Remove Bank",
          style: TextStyle(color: _white, fontFamily: _dmSans),
        ),
        content: const Text(
          "Are you sure you want to remove this bank account?",
          style: TextStyle(color: _grey, fontFamily: _dmSans),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: _grey, fontFamily: _dmSans),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _controller.userBankDelete(widget.preBank?.id ?? 0);
            },
            child: const Text(
              "Remove",
              style: TextStyle(color: Colors.red, fontFamily: _dmSans),
            ),
          ),
        ],
      ),
    );
  }
}
