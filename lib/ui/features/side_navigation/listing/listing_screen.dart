import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:tradexpro_flutter/ui/features/root/prefetch_service.dart';

const _kBase = 'https://api.trapix.com';
const _lime = Color(0xFFCCFF00);
const _bg = Color(0xFF111111);
const _card = Color(0xFF1A1A1A);
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
  Map<String, dynamic>? _submitted;
  final Map<int, String> _answers = {};
  final Map<int, String> _errors = {};
  String? _globalError;
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _fieldKeys = {};

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PrefetchService>()) {
      final cached = PrefetchService.to.listingFormSections;
      if (cached.isNotEmpty) {
        _sections = List.from(cached);
        _loading = false;
        // Pre-select first option for select/radio fields from cache
        for (final section in _sections) {
          for (final q in (section['questions'] as List? ?? [])) {
            final ft = q['field_type'] as String? ?? '';
            if (ft == 'select' || ft == 'radio') {
              final qId = q['id'] as int;
              final opts = (q['options'] as List?)?.cast<String>() ?? [];
              if (opts.isNotEmpty && !_answers.containsKey(qId)) {
                _answers[qId] = opts.first;
              }
            }
          }
        }
      }
    }
    _loadForm();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadForm() async {
    setState(() { if (_sections.isEmpty) _loading = true; });
    try {
      final res = await http.get(Uri.parse('$_kBase/api/v1/listing-form'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final sections = data['sections'] ?? [];
        // Pre-select first option for all select/radio fields
        for (final section in sections) {
          for (final q in (section['questions'] as List? ?? [])) {
            final ft = q['field_type'] as String? ?? '';
            if (ft == 'select' || ft == 'radio') {
              final qId = q['id'] as int;
              final opts = (q['options'] as List?)?.cast<String>() ?? [];
              if (opts.isNotEmpty && !_answers.containsKey(qId)) {
                _answers[qId] = opts.first;
              }
            }
          }
        }
        if (mounted) {
          setState(() => _sections = sections);
          if (Get.isRegistered<PrefetchService>()) PrefetchService.to.listingFormSections.assignAll(sections);
        }
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
      final firstErrorId = _errors.keys.first;
      final key = _fieldKeys[firstErrorId];
      if (key?.currentContext != null) {
        await Scrollable.ensureVisible(key!.currentContext!,
            duration: const Duration(milliseconds: 400), alignment: 0.3);
      }
      return;
    }
    setState(() {
      _submitting = true;
      _globalError = null;
    });
    try {
      final res = await http.post(
        Uri.parse('$_kBase/api/v1/listing-form/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'answers': _answers}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          setState(() => _submitted = {
                'reference_id': data['reference_id'],
                'message': data['message']
              });
        }
      } else {
        if (mounted) {
          setState(() =>
              _globalError = data['message'] ?? 'Submission failed. Please try again.');
        }
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
      backgroundColor: const Color(0xFF111111),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _lime))
          : _sections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Form not available.',
                          style: TextStyle(color: _grey, fontSize: 15)),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _loadForm,
                        child: const Text('Retry', style: TextStyle(color: _lime)),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        children: [
                          _buildHeroHeader(context),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        color: const Color(0xFF1A1A1A),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_globalError != null) _buildGlobalError(),
                            ..._sections.asMap().entries
                                .map((e) => _buildSection(e.key, e.value)),
                            _buildSubmitSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 240 + topPad,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/listing.png', fit: BoxFit.cover),
          Container(color: Colors.transparent),
          Padding(
            padding: EdgeInsets.only(top: topPad),
            child: Column(
              children: [
                // top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: Get.back,
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      Image.asset('assets/images/tlogo.png', height: 38),
                    ],
                  ),
                ),
                // title block
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Column(
                    children: [
                      const Text(
                        'Listing Application Form',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          fontFamily: "DMSans",
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                       Text(
                        'Launch, List, and Scale Your Crypto Project\nWith Us.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                          fontFamily: "DMSans",
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'www.trapix.com',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1,
                          fontWeight: FontWeight.w400,
                          fontFamily: "DMSans",
                        ),
                      ),
                    ],
                  ),
                ),
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
          Expanded(
            child: Text(_globalError!,
                style: const TextStyle(color: Color(0xFFF87171), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(int sectionIndex, dynamic section) {
    final questions = section['questions'] as List? ?? [];

    // Pre-init all keys in this section
    for (final q in questions) {
      final qId = q['id'] as int;
      _fieldKeys[qId] ??= GlobalKey();
    }

    final rows = <Widget>[];
    int i = 0;
    while (i < questions.length) {
      final q1 = questions[i];
      final ft1 = q1['field_type'] as String? ?? 'text';
      final qId1 = q1['id'] as int;
      final canPair1 = !['textarea', 'radio', 'checkbox'].contains(ft1);

      if (canPair1 && i + 1 < questions.length) {
        final q2 = questions[i + 1];
        final ft2 = q2['field_type'] as String? ?? 'text';
        final canPair2 = !['textarea', 'radio', 'checkbox'].contains(ft2);

        if (canPair2) {
          final qId2 = q2['id'] as int;
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: KeyedSubtree(
                      key: _fieldKeys[qId1],
                      child: _buildQuestion(q1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KeyedSubtree(
                      key: _fieldKeys[qId2],
                      child: _buildQuestion(q2),
                    ),
                  ),
                ],
              ),
            ),
          );
          i += 2;
          continue;
        }
      }

      rows.add(
        Padding(
          key: _fieldKeys[qId1],
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildQuestion(q1),
        ),
      );
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section['title'] ?? '',
          style: const TextStyle(
            color: _lime,
            fontSize: 16,
            height: 20/16,
            fontWeight: FontWeight.w400,
            fontFamily: "DMSans",
          ),
        ),
        if (section['description'] != null &&
            (section['description'] as String).isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(section['description'],
              style:  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: "DMSans")),
        ],
        const SizedBox(height: 14),
        ...rows,
        const SizedBox(height: 8),
      ],
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
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: "DMSans",
                height: 16 / 12),
            children: [
              TextSpan(text: q['label'] ?? ''),
              if (isRequired)
                const TextSpan(text: '*', style: TextStyle(color: _lime)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _buildField(q, hasError),
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFF87171), size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(_errors[qId]!,
                    style: const TextStyle(color: Color(0xFFF87171), fontSize: 11)),
              ),
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

    final borderColor =
        hasError ? _red.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08);
    final fillColor =
        hasError ? _red.withValues(alpha: 0.05) : const Color(0xFF111111);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: fillColor,
      hintText: placeholder.isNotEmpty ? placeholder : null,
      hintStyle: const TextStyle(color: _grey, fontSize: 12, fontFamily: "DMSans"),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lime, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );

    if (fieldType == 'date') {
      return GestureDetector(
        onTap: () async {
          DateTime initial = DateTime.now();
          if (val.isNotEmpty) {
            try {
              initial = DateFormat('dd-MM-yyyy').parse(val);
            } catch (_) {}
          }
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            builder: (ctx, child) => Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: _lime,
                  onPrimary: Colors.black,
                  surface: _card,
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            _handleChange(qId, DateFormat('dd-MM-yyyy').format(picked));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  color: val.isEmpty ? _grey : Colors.white, size: 15),
              const SizedBox(width: 10),
              Text(
                val.isEmpty ? 'DD-MM-YYYY' : val,
                style: TextStyle(
                  color: val.isEmpty ? _grey : Colors.white,
                  fontSize: 12,
                  fontFamily: "DMSans",
                  height: 20 / 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (fieldType == 'textarea') {
      return TextFormField(
        initialValue: val,
        onChanged: (v) => _handleChange(qId, v),
        minLines: 4,
        maxLines: null,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: "DMSans", height: 20 / 12),
        decoration: inputDecoration,
      );
    }

    if (fieldType == 'radio') {
      return _ListingDropdown(
        options: options,
        value: val.isEmpty ? null : val,
        hint: 'Select',
        hasError: hasError,
        onChanged: (v) => _handleChange(qId, v),
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
                border: Border.all(
                    color: isChecked
                        ? _lime.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: isChecked ? _lime : Colors.white.withValues(alpha: 0.2),
                          width: 2),
                      color: isChecked ? _lime : Colors.transparent,
                    ),
                    child: isChecked
                        ? const Icon(Icons.check, size: 11, color: Colors.black)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(opt,
                      style: TextStyle(
                          color: isChecked ? Colors.white : Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: "DMSans")),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    if (fieldType == 'select') {
      return _ListingDropdown(
        options: options,
        value: val.isEmpty ? null : val,
        hint: 'Select',
        hasError: hasError,
        onChanged: (v) => _handleChange(qId, v),
      );
    }

    // text / url / email / number
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
      style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: "DMSans", height: 20 / 12),
      decoration: inputDecoration,
    );
  }

  Widget _buildSubmitSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color:Colors.transparent),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: _lime, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Listing approval usually takes 24–48 hours after successful submission.',
                  style: TextStyle(color: _lightGrey, fontSize: 12, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCCFF00),
              foregroundColor: Colors.black,
              disabledBackgroundColor: _lime.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                  )
                : const Text(
                    'Submit',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFamily: "DMSans",),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── overlay dropdown ─────────────────────────────────
class _ListingDropdown extends StatefulWidget {
  final List<String> options;
  final String? value;
  final String hint;
  final bool hasError;
  final void Function(String) onChanged;

  const _ListingDropdown({
    required this.options,
    required this.value,
    required this.hint,
    required this.hasError,
    required this.onChanged,
  });

  @override
  State<_ListingDropdown> createState() => _ListingDropdownState();
}

class _ListingDropdownState extends State<_ListingDropdown> {
  OverlayEntry? _overlay;
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;

    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              offset: Offset(0, size.height + 4),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.options.map((opt) {
                      final isSelected = opt == widget.value;
                      return GestureDetector(
                        onTap: () {
                          _close();
                          widget.onChanged(opt);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: isSelected ? _lime : Colors.white,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontFamily: 'DMSans',
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlay!);
    setState(() => _isOpen = true);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasVal = widget.value != null && widget.value!.isNotEmpty;
    final borderColor = widget.hasError
        ? _red.withValues(alpha: 0.5)
        : _isOpen
            ? _lime
            : Colors.white.withValues(alpha: 0.08);
    final fillColor = widget.hasError
        ? _red.withValues(alpha: 0.05)
        : const Color(0xFF111111);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _isOpen ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasVal ? widget.value! : widget.hint,
                  style: TextStyle(
                    color: hasVal ? Colors.white : _grey,
                    fontSize: 12,
                    fontFamily: 'DMSans',
                    height: 20 / 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: _lime,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3),
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
                      const Text('YOUR REFERENCE ID',
                          style: TextStyle(
                              color: _grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1)),
                      const SizedBox(height: 6),
                      Text(
                        data['reference_id']?.toString() ?? '—',
                        style: const TextStyle(
                            color: _lime,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Back to Home',
                        style: TextStyle(fontWeight: FontWeight.w600)),
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
