import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

const _kBase = 'https://api.trapix.com';
const _lime = Color(0xFFCCFF00);
const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF181818);
const _border = Color(0xFF222222);
const _grey = Color(0xFF888888);
const _lightGrey = Color(0xFFAAAAAA);
const _red = Color(0xFFEF4444);

class ListingScreen extends StatefulWidget {
  const ListingScreen({super.key});

  @override
  State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> {
  List<dynamic> _sections = [];
  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic>? _submitted; // {reference_id, message}
  final Map<int, String> _answers = {};
  final Map<int, String> _errors = {};
  String? _globalError;
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _fieldKeys = {};

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadForm() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_kBase/api/v1/listing-form'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) setState(() => _sections = data['sections'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _handleChange(int qId, String value) {
    setState(() {
      _answers[qId] = value;
      _errors.remove(qId);
    });
  }

  void _handleCheckbox(int qId, String option, bool checked) {
    final current = (_answers[qId] ?? '').split(', ').where((s) => s.isNotEmpty).toList();
    if (checked) {
      if (!current.contains(option)) current.add(option);
    } else {
      current.remove(option);
    }
    _handleChange(qId, current.join(', '));
  }

  bool _validate() {
    final newErrors = <int, String>{};
    for (final section in _sections) {
      for (final q in section['questions'] as List) {
        final qId = q['id'] as int;
        if (q['is_required'] == true && (_answers[qId]?.trim() ?? '').isEmpty) {
          newErrors[qId] = '${q['label']} is required';
        }
      }
    }
    setState(() => _errors.addAll(newErrors));
    return newErrors.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      // Scroll to first error field
      final firstErrorId = _errors.keys.first;
      final key = _fieldKeys[firstErrorId];
      if (key?.currentContext != null) {
        await Scrollable.ensureVisible(key!.currentContext!, duration: const Duration(milliseconds: 400), alignment: 0.3);
      }
      return;
    }
    setState(() { _submitting = true; _globalError = null; });
    try {
      final res = await http.post(
        Uri.parse('$_kBase/api/v1/listing-form/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'answers': _answers}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) setState(() => _submitted = {'reference_id': data['reference_id'], 'message': data['message']});
      } else {
        if (mounted) setState(() => _globalError = data['message'] ?? 'Submission failed. Please try again.');
      }
    } catch (_) {
      if (mounted) setState(() => _globalError = 'Submission failed. Please try again.');
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted != null) return _SuccessScreen(data: _submitted!);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: Get.back,
        ),
        title: const Text('Token Listing', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _lime))
          : _sections.isEmpty
              ? const Center(child: Text('Form not available.', style: TextStyle(color: _grey)))
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeader(),
                          if (_globalError != null) _buildGlobalError(),
                          ..._sections.asMap().entries.map((e) => _buildSection(e.key, e.value)),
                          _buildSubmitSection(),
                        ]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _lime.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _lime.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.check_circle_outline, color: _lime, size: 26),
          ),
          const SizedBox(height: 16),
          const Text(
            'Token Listing Application',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Thank you for your interest in listing on Trapix. Please complete this form carefully and ensure all details are accurate.',
            style: TextStyle(color: _grey, fontSize: 13, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: _grey, size: 14),
                SizedBox(width: 6),
                Text('Due to high volume, processing may take some time.', style: TextStyle(color: _grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(_globalError!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildSection(int sectionIndex, dynamic section) {
    final questions = section['questions'] as List? ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: _lime.withValues(alpha: 0.03),
              border: const Border(bottom: BorderSide(color: Color(0xFF1E1E1E))),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(color: _lime, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '${sectionIndex + 1}',
                      style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      if (section['description'] != null && (section['description'] as String).isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(section['description'], style: const TextStyle(color: _grey, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Questions
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: questions.asMap().entries.map((entry) {
                final q = entry.value;
                final qId = q['id'] as int;
                _fieldKeys[qId] ??= GlobalKey();
                return Padding(
                  key: _fieldKeys[qId],
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildQuestion(q),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(dynamic q) {
    final qId = q['id'] as int;
    final hasError = _errors.containsKey(qId);
    final isRequired = q['is_required'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
            children: [
              TextSpan(text: q['label'] ?? ''),
              if (isRequired)
                const TextSpan(text: ' *', style: TextStyle(color: _red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildField(q, hasError),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFF87171), size: 12),
              const SizedBox(width: 4),
              Text(_errors[qId]!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildField(dynamic q, bool hasError) {
    final qId = q['id'] as int;
    final val = _answers[qId] ?? '';
    final fieldType = q['field_type'] as String? ?? 'text';
    final options = (q['options'] as List?)?.cast<String>() ?? [];
    final placeholder = q['placeholder'] as String? ?? '';

    final borderColor = hasError ? _red.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1);
    final fillColor = hasError ? _red.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.04);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: fillColor,
      hintText: placeholder.isNotEmpty ? placeholder : null,
      hintStyle: const TextStyle(color: _grey, fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _lime, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

    if (fieldType == 'textarea') {
      return TextFormField(
        initialValue: val,
        onChanged: (v) => _handleChange(qId, v),
        minLines: 4,
        maxLines: null,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: inputDecoration,
      );
    }

    if (fieldType == 'radio') {
      return Column(
        children: options.map((opt) {
          final selected = val == opt;
          return GestureDetector(
            onTap: () => _handleChange(qId, opt),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: selected ? _lime.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? _lime : Colors.white.withValues(alpha: 0.2), width: 2),
                      color: selected ? _lime : Colors.transparent,
                    ),
                    child: selected
                        ? const Center(child: SizedBox(width: 7, height: 7, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle))))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(opt, style: TextStyle(color: selected ? Colors.white : _lightGrey, fontSize: 14)),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    if (fieldType == 'checkbox') {
      final checked = val.split(', ').where((s) => s.isNotEmpty).toList();
      return Column(
        children: options.map((opt) {
          final isChecked = checked.contains(opt);
          return GestureDetector(
            onTap: () => _handleCheckbox(qId, opt, !isChecked),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: isChecked ? _lime.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isChecked ? _lime : Colors.white.withValues(alpha: 0.2), width: 2),
                      color: isChecked ? _lime : Colors.transparent,
                    ),
                    child: isChecked ? const Icon(Icons.check, size: 11, color: Colors.black) : null,
                  ),
                  const SizedBox(width: 10),
                  Text(opt, style: TextStyle(color: isChecked ? Colors.white : _lightGrey, fontSize: 14)),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    if (fieldType == 'select') {
      return Container(
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: val.isEmpty ? null : val,
            hint: const Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Text('— Select an option —', style: TextStyle(color: _grey, fontSize: 13))),
            dropdownColor: _card,
            isExpanded: true,
            icon: const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.keyboard_arrow_down, color: _grey)),
            items: options.map((opt) => DropdownMenuItem(
              value: opt,
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text(opt, style: const TextStyle(color: Colors.white, fontSize: 14))),
            )).toList(),
            onChanged: (v) { if (v != null) _handleChange(qId, v); },
          ),
        ),
      );
    }

    // default: text / url / email / number
    final keyboardType = fieldType == 'number'
        ? const TextInputType.numberWithOptions(decimal: true)
        : fieldType == 'email'
            ? TextInputType.emailAddress
            : fieldType == 'url'
                ? TextInputType.url
                : TextInputType.text;

    return TextFormField(
      initialValue: val,
      onChanged: (v) => _handleChange(qId, v),
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: inputDecoration,
    );
  }

  Widget _buildSubmitSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(
        children: [
          const Text(
            'By submitting this form, you confirm that all information provided is accurate. A reference ID will be generated for your application.',
            style: TextStyle(color: _grey, fontSize: 12, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _lime,
                foregroundColor: Colors.black,
                disabledBackgroundColor: _lime.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Submit Application', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── success screen ───────────────────────────────────
class _SuccessScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SuccessScreen({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: Get.back,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: _lime, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.black, size: 36),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Application Submitted!',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                if (data['message'] != null)
                  Text(
                    data['message'],
                    style: const TextStyle(color: _grey, fontSize: 14, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: _lime.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _lime.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      const Text('YOUR REFERENCE ID', style: TextStyle(color: _grey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      const SizedBox(height: 6),
                      Text(
                        data['reference_id']?.toString() ?? '—',
                        style: const TextStyle(color: _lime, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'We will contact you via your official email and Telegram. Please save your reference ID.',
                  style: TextStyle(color: _grey, fontSize: 12, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: Get.back,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
