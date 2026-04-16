import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/extensions.dart';
import '../../../../../data/models/bank_data.dart';
import '../../../../../data/models/dynamic_form.dart';
import '../../../../ui_helper/bank_widgets.dart';
import 'user_bank_controller.dart';

const _bg      = Color(0xFF111111);
const _fieldBg = Color(0xFF1A1A1A);
const _green   = Color(0xFFCCFF00);
const _white   = Color(0xFFFFFFFF);
const _grey    = Color(0x80FFFFFF);
const _dmSans  = 'DMSans';

class BankInputPage extends StatefulWidget {
  const BankInputPage({super.key, this.preBank});
  final DynamicBank? preBank;

  @override
  State<BankInputPage> createState() => _BankInputPageState();
}

class _BankInputPageState extends State<BankInputPage> {
  final _controller = Get.find<UserBankController>();
  Rx<BankForm> selectedBank = BankForm().obs;
  final RxInt _selectedBankIndex = (-1).obs;

  @override
  void initState() {
    super.initState();
    if (widget.preBank == null) {
      // Load bank forms list
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.getBankFormList());
    } else {
      _updatePreBankData(widget.preBank);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.getBankDetails(widget.preBank?.id ?? 0, _updatePreBankData);
      });
    }
  }

  void _updatePreBankData(DynamicBank? preBank) {
    final bankItems = preBank?.bank ?? {};
    final bankForm  = preBank?.bankForm ?? BankForm();
    for (String slug in bankItems.keys) {
      final value = bankItems[slug]?.value ?? '';
      final field = bankForm.fields?.firstWhereOrNull((e) => e.slug == slug);
      if (field != null) field.controllerL = TextEditingController(text: value);
    }
    selectedBank.value = bankForm;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit   = widget.preBank != null;
    final btnTitle = isEdit ? "Update Bank" : "Save Bank";

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios_new, color: _white, size: 18),
        ),
        title: Text(
          isEdit ? "Bank Details" : "Add Bank",
          style: const TextStyle(
            color: _white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: _dmSans,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final fields = selectedBank.value.fields ?? [];
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                children: [

                  // ── BANK SELECTOR — shown as inline list ──────────
                  if (!isEdit) ...[
                    _label("Select Bank"),
                    const SizedBox(height: 10),
                    Obx(() => _controller.bankForms.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: _green),
                            ),
                          )
                        : Column(
                            children: _controller.bankForms.asMap().entries.map((entry) {
                              final i    = entry.key;
                              final form = entry.value;
                              final isSelected = _selectedBankIndex.value == i;
                              return GestureDetector(
                                onTap: () {
                                  _selectedBankIndex.value = i;
                                  _setSelectedBankForm(i);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? _green.withOpacity(0.1) : _fieldBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? _green : Colors.white.withOpacity(0.2),
                                      width: isSelected ? 1.5 : 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          form.title ?? "",
                                          style: TextStyle(
                                            color: isSelected ? _green : _white,
                                            fontSize: 15,
                                            fontFamily: _dmSans,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.check_circle, color: _green, size: 20),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          )),
                    const SizedBox(height: 20),
                  ],

                  // ── DYNAMIC FIELDS ────────────────────────────────
                  ...fields.map((field) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(field.title ?? ""),
                        const SizedBox(height: 6),
                        Container(
                          height: 58,
                          decoration: BoxDecoration(
                            color: _fieldBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: field.errorL.isValid
                                  ? Colors.red.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: TextField(
                            controller: field.controllerL,
                            style: const TextStyle(
                              color: _white,
                              fontSize: 15,
                              fontFamily: _dmSans,
                            ),
                            onChanged: (_) => selectedBank.refresh(),
                            decoration: InputDecoration(
                              hintText: field.title ?? "",
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
                        if (field.errorL.isValid)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              field.errorL ?? "",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontFamily: _dmSans,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            // ── BOTTOM BUTTONS ──────────────────────────────────────
            if (fields.isNotEmpty || isEdit) ...[

              // Remove Bank (edit only)
              if (isEdit)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 0.5),
                        backgroundColor: _fieldBg,
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
              if (fields.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
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
                      onPressed: _nextButtonAction,
                      child: Text(
                        btnTitle,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: _dmSans,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      }),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _grey,
        fontSize: 12,
        fontFamily: _dmSans,
      ),
    );
  }

  void _setSelectedBankForm(int index) {
    final form = _controller.bankForms[index];
    for (DynamicField field in (form.fields ?? [])) {
      field.controllerL = TextEditingController();
    }
    selectedBank.value = form;
  }

  void _nextButtonAction() {
    bool hasError = false;
    final fieldList = selectedBank.value.fields ?? [];
    for (final field in fieldList) {
      if (field.errorL.isValid) hasError = true;
      final valueL = field.controllerL?.text.trim() ?? '';
      if (field.required == 1 && !valueL.isValid) {
        field.errorL = "${field.title ?? ''} ${"is required".tr}".toCapitalizeFirst();
        hasError = true;
      }
    }
    hasError ? selectedBank.refresh() : _saveOrUpdateBank();
  }

  void _saveOrUpdateBank() {
    hideKeyboard();
    selectedBank.value.bankIdL = widget.preBank?.id;
    selectedBank.value.access  = BankAccessType.user.toString();
    _controller.userBankSave(selectedBank.value);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _fieldBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Remove Bank",
            style: TextStyle(color: _white, fontFamily: _dmSans)),
        content: const Text(
            "Are you sure you want to remove this bank account?",
            style: TextStyle(color: _grey, fontFamily: _dmSans)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(color: _grey, fontFamily: _dmSans)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _controller.userBankDelete(widget.preBank?.id ?? 0);
              Get.back();
            },
            child: const Text("Remove",
                style: TextStyle(color: Colors.red, fontFamily: _dmSans)),
          ),
        ],
      ),
    );
  }
}