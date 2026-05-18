import 'dart:convert';
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/utils/common_utils.dart';

const _kBase = 'https://api.trapix.com';
const _lime = Color(0xFFCCFF00);
const _bg = Color(0xFF0D0D0D);
const _grey = Color(0xFF888888);
const _lightGrey = Color(0xFFAAAAAA);
const _red = Color(0xFFFF3C3C);

// ─────────────────────────── Platform definitions ──────────────────────────

class _PlatformDef {
  final String key;
  final String label;
  final String placeholder;
  final String svg;
  const _PlatformDef(this.key, this.label, this.placeholder, this.svg);
}

const _svgEmail =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>';

const _svgTelegram =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="white"><path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/></svg>';

const _svgInstagram =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="white"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 1 0 0 12.324 6.162 6.162 0 0 0 0-12.324zM12 16a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm6.406-11.845a1.44 1.44 0 1 0 0 2.881 1.44 1.44 0 0 0 0-2.881z"/></svg>';

const _svgFacebook =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="white"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>';

const _svgTwitter =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="white"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>';

const _svgWhatsApp =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="white"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 0 1-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 0 1-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 0 1 2.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0 0 12.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 0 0 5.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 0 0-3.48-8.413z"/></svg>';

const _svgPhone =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 13.1 19.79 19.79 0 0 1 1.61 4.5 2 2 0 0 1 3.6 2.31h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L7.91 9.91a16 16 0 0 0 6.18 6.18l.95-.95a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 21.97 17z"/></svg>';

const _svgBadge =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L3 6v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V6l-9-4z"/><polyline points="9 12 11 14 15 10"/></svg>';

const _svgShield =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>';

const _platforms = [
  _PlatformDef('email', 'Email', 'Enter email address', _svgEmail),
  _PlatformDef(
    'telegram',
    'Telegram',
    'Enter @username or username',
    _svgTelegram,
  ),
  _PlatformDef('instagram', 'Instagram', 'Enter @username', _svgInstagram),
  _PlatformDef(
    'facebook',
    'Facebook',
    'Enter profile URL or name',
    _svgFacebook,
  ),
  _PlatformDef('twitter', 'Twitter / X', 'Enter @handle', _svgTwitter),
  _PlatformDef(
    'whatsapp',
    'WhatsApp',
    'Enter phone e.g. +971...',
    _svgWhatsApp,
  ),
  _PlatformDef('phone', 'Phone', 'Enter phone number', _svgPhone),
];

String _getContactLink(String platform, String handle) {
  final h = handle.replaceAll(RegExp(r'^@'), '');
  switch (platform) {
    case 'email':
      return 'mailto:$handle';
    case 'telegram':
      return 'https://t.me/$h';
    case 'instagram':
      return 'https://instagram.com/$h';
    case 'facebook':
      return handle.startsWith('http') ? handle : 'https://facebook.com/$h';
    case 'twitter':
      return 'https://x.com/$h';
    case 'whatsapp':
      return 'https://wa.me/${handle.replaceAll(RegExp(r'[^0-9]'), '')}';
    case 'phone':
      return 'tel:$handle';
    default:
      return handle;
  }
}

String? _svgForPlatform(String platform) {
  for (final p in _platforms) {
    if (p.key == platform) return p.svg;
  }
  return null;
}

// ─────────────────────────── Corner rotate painter ─────────────────────────

class _CornerRotatePainter extends CustomPainter {
  final double angle;
  const _CornerRotatePainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final corners = [
      Offset(0, 0),   // top-left  → purple
      Offset(w, 0),   // top-right → blue
      Offset(w, h),   // bot-right → pink
      Offset(0, h),   // bot-left  → green
    ];
    const colors = [
      Color(0xFF8500B9),
      Color(0xFF2986FF),
      Color(0xFFFF8484),
      Color(0xFF4ED78E),
    ];

    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(angle);
    canvas.translate(-w / 2, -h / 2);

    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        corners[i],
        160,
        Paint()
          ..color = colors[i].withValues(alpha: 0.65)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 95),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CornerRotatePainter old) => old.angle != angle;
}

// ─────────────────────────── Screen ────────────────────────────────────────

class OfficialVerificationScreen extends StatefulWidget {
  const OfficialVerificationScreen({super.key});

  @override
  State<OfficialVerificationScreen> createState() =>
      _OfficialVerificationScreenState();
}

class _OfficialVerificationScreenState
    extends State<OfficialVerificationScreen>
    with SingleTickerProviderStateMixin {
  _PlatformDef _selectedPlatform = _platforms[0];
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;
  Map<String, dynamic>? _result;

  late AnimationController _blobController;
  late Animation<double> _blobAnim;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _blobAnim = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _blobController, curve: Curves.linear),
    );
    _blobController.repeat();
  }

  @override
  void dispose() {
    _blobController.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── logic ──

  Future<void> _verify() async {
    final q = _textCtrl.text.trim();
    if (q.isEmpty) return;

    // Verify pe click = keyboard aur blinking cursor band
    _focusNode.unfocus();

    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final uri = Uri.parse('$_kBase/api/v1/verification/verify').replace(
        queryParameters: {'platform': _selectedPlatform.key, 'query': q},
      );
      final res = await http.get(uri);
      setState(() => _result = jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      setState(
        () => _result = {
          'found': false,
          'message': 'Verification service unavailable. Please try again.',
        },
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _textCtrl.clear();
    });
    Future.delayed(
      const Duration(milliseconds: 100),
      () => _focusNode.requestFocus(),
    );
  }

  void _selectPlatform(_PlatformDef p) {
    setState(() {
      _selectedPlatform = p;
      _result = null;
      _textCtrl.clear();
    });
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Screen pe kahin bhi tap = keyboard + cursor band
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: const Color(0xFF111111),
        appBar: AppBar(
          backgroundColor: const Color(0xFF111111),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 25,
            ),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'Official Verification',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              children: [
                // ── 1. Colorful blob card: badge + title + desc + pills + input
                _buildColorCard(),

                const SizedBox(height: 12),

                // ── 2. Verify button: alag, card ke bahar, full width
               

                // ── 3. Result section (verify ke baad dikhta hai)
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  _buildResult(),
                ],

                const SizedBox(height: 28),

                // ── 4. Footer
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Colorful blob card (badge + title + desc + pills + input only) ────────

  Widget _buildColorCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // ── 4 colored corner blobs rotating clockwise (corner to corner) ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _blobAnim,
              builder: (context, child) => CustomPaint(
                painter: _CornerRotatePainter(_blobAnim.value),
              ),
            ),
          ),

          // ── content: badge, title, description, pills, input ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // badge icon
                SvgPicture.string(
                  _svgBadge,
                  width: 30,
                  height: 30,
                  colorFilter: const ColorFilter.mode(_lime, BlendMode.srcIn),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Contact Verifier',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verify emails, Telegram IDs, phone numbers, or social accounts to confirm they belong to official Trapix staff.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 22),

                // platform pills
                _buildPlatformPills(),
                const SizedBox(height: 16),

                // input field — card ke andar, bottom pe
                _buildInputField(),
                SizedBox(height: 20),
                 _buildVerifyButton(),
              ],
            ),
          ),
          
        ],
      ),
    );
  }

  // ── platform pills ──

  Widget _buildPlatformPills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _platforms.map((p) {
        final active = p.key == _selectedPlatform.key;
        return GestureDetector(
          onTap: () => _selectPlatform(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: active ? _lime : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: active ? _lime : Colors.white.withValues(alpha: 0.12),
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.string(
                  p.svg,
                  width: 13,
                  height: 13,
                  colorFilter: ColorFilter.mode(
                    active ? Colors.black : const Color(0xFFAAAAAA),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  p.label,
                  style: TextStyle(
                    color: active ? Colors.black : const Color(0xFFAAAAAA),
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── input field ──

  Widget _buildInputField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          SvgPicture.string(
            _selectedPlatform.svg,
            width: 15,
            height: 15,
            colorFilter:  ColorFilter.mode(
              Color(0xFFFFFFFF).withOpacity(0.5),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: _lime,
              decoration: InputDecoration(
                hintText: _selectedPlatform.placeholder,
                hintStyle: TextStyle(
                  color: Color(0xFFFFFFFF).withOpacity(0.5),
                  fontSize: 16,
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w700,
                  height: 20/16,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _verify(),
              onChanged: (_) => setState(() => _result = null),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  // ── Verify button — card ke BAHAR, alag, full width ──────────────────────

  Widget _buildVerifyButton() {
    final isEmpty = _textCtrl.text.trim().isEmpty;
    return GestureDetector(
      onTap: (_loading || isEmpty) ? null : _verify,
      child: AnimatedOpacity(
        opacity: (_loading || isEmpty) ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: _lime,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF111111),
                    ),
                  )
                : const Text(
                    'Verify',
                    style: TextStyle(
                      color: Color(0xFF111111),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 20/16,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── result box ──

  Widget _buildResult() {
    final found = _result!['found'] == true;
    return Container(
      decoration: BoxDecoration(
        color: found
            ? Color(0xFF1A1A1A)
            : Color(0xFF1A1A1A),
        border: Border.all(
          color: found
              ? _lime.withValues(alpha: 0.25)
              : _red.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20,bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             
              const SizedBox(width: 12),
              Expanded(
                child: found ? _buildFoundContent() : _buildNotFoundContent(),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: _reset,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFF111111),
                  border: Border.all(color: const Color(0xFF1A1A1A)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Verify another contact',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: "DMSans", fontWeight: FontWeight.w400),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── found content ──

  Widget _buildFoundContent() {
    final staff = _result!['staff'] as Map<String, dynamic>?;
    final contacts =
        (_result!['contacts'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✓  Official Trapix Staff',
          style: TextStyle(
            color: _lime,
            fontSize: 16,
            height: 20/16,
            fontFamily: "DMSans",
            fontWeight: FontWeight.w700,
          ),
        ),
        if (staff != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAvatar(staff),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff['name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((staff['title'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        staff['title'],
                        style:  TextStyle(color: Colors.white.withOpacity(0.5) , fontSize: 12, fontFamily: "DMSans", fontWeight: FontWeight.w400),
                      ),
                    ],
                    if ((staff['department'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF111111),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          staff['department'],
                          style: const TextStyle(color: _lime, fontSize: 10, fontFamily: "DMSans", fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
        if (contacts.isNotEmpty) ...[
          const SizedBox(height: 14),
           Text(
            'All official contacts for this person:',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: "DMSans", fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: contacts.map((c) {
              final platform = c['platform'] as String? ?? '';
              final handle = c['display_handle'] as String? ?? '';
              final link = _getContactLink(platform, handle);
              final svgStr = _svgForPlatform(platform);
              final isExternal = !['email', 'phone'].contains(platform);
              return GestureDetector(
                onTap: () => openUrlInBrowser(link),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(color: const Color(0xFF333333)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (svgStr != null) ...[
                        SvgPicture.string(
                          svgStr,
                          width: 11,
                          height: 11,
                          colorFilter: const ColorFilter.mode(
                            _lime,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        handle,
                        style:  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                      ),
                      if (isExternal) ...[
                        const SizedBox(width: 3),
                         Icon(Icons.open_in_new, size: 9, color:Colors.white.withOpacity(0.5) ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ── not found content ──

  Widget _buildNotFoundContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚠  Not an Official Contact',
          style: TextStyle(
            color: _red,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 20/16,
            fontFamily: "DMSans",
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _result!['message'] ?? '',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.5, fontFamily: "DMSans", fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:Color(0xFF111111),
            border: Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: RichText(
            text:  TextSpan(
              text:
                  'Do not share passwords, funds, or personal information with this person. Official Trapix staff will ',
              style: TextStyle(
                color: Colors.red.withOpacity(0.5),
                fontSize: 12,
                height: 1.5,
                fontFamily: "DMSans",
                fontWeight: FontWeight.w400
              ),
              children: [
                TextSpan(
                  text: 'never',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' ask for your password.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── avatar ──

  Widget _buildAvatar(Map<String, dynamic> staff) {
    final avatarUrl = staff['avatar'] as String?;
    final initials = staff['initials'] as String? ?? '';
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(color: _lime, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: (avatarUrl != null && avatarUrl.isNotEmpty)
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
    );
  }

  // ── footer ──

  Widget _buildFooter() {
    return Row(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    SvgPicture.string(
      _svgShield,
      width: 25,
      height: 25,
      colorFilter: ColorFilter.mode(
        Color(0xFFCCFF00),
        BlendMode.srcIn,
      ),
    ),

    const SizedBox(width: 5),

    Flexible(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text:
              'All lookups are logged to help detect phishing attempts. Report suspicious activity to ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            height: 1.5,
            fontFamily: "DMSans",
            fontWeight: FontWeight.w400,
          ),
          children: [
            TextSpan(
              text: 'security@trapix.com',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: "DMSans",
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  ],
);
  }
}