import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

const Color _bg = Color(0xFF111111);
const Color _secondary = Color(0xFF1A1A1A);
const Color _green = Color(0xFF00B052);
const Color _yellow = Color(0xFFE0B341);
const Color _red = Color(0xFFD73C3C);
const Color _blue = Color(0xFF00B7FF);
const Color _grey = Color(0xFF888888);
const Color _accent = Color(0xFFCCFF00);
const String _font = 'DM Sans';

class TxDetailScreen extends StatelessWidget {
  final Map<String, dynamic> tx;
  const TxDetailScreen({super.key, required this.tx});

  bool get _isDep => tx['_type'] == 'deposit';

  // Truncate like web: first 18 + … + last 8 if > 30 chars
  String _short(String s) =>
      s.length > 30 ? '${s.substring(0, 18)}…${s.substring(s.length - 8)}' : s;

  String _fmtAmt(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '0') ?? 0;
    return d.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _statusLabel(dynamic status) {
    switch (status?.toString()) {
      case '1': return 'Success';
      case '0': case '4': return 'Pending';
      case '5': return 'Processing';
      case '2': return 'Rejected';
      case '99': return 'Expired';
      default: return 'Failed';
    }
  }

  Color _statusColor(String label) {
    if (label == 'Success') return _green;
    if (label == 'Pending') return _yellow;
    if (label == 'Processing') return _blue;
    if (label == 'Expired') return _grey;
    return _red;
  }

  String _formatDate(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
    } catch (_) { return raw.toString(); }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _copy(BuildContext context, String text) {
    if (text == '—' || text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1), backgroundColor: Color(0xFF222222)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coin = tx['coin_type']?.toString() ?? 'USDT';
    final rawAmt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
    // received = amount - fee for withdraw, just amount for deposit
    final fee = double.tryParse((tx['fees'] ?? tx['fee'] ?? 0).toString()) ?? 0;
    final received = _isDep ? rawAmt : (rawAmt - fee).clamp(0.0, double.infinity);
    final amtDisplay = _fmtAmt(received == 0 ? rawAmt : received);
    final feeDisplay = fee.toStringAsFixed(2);

    final statusLabel = _statusLabel(tx['status']);
    final statusColor = _statusColor(statusLabel);
    final time = _formatDate(tx['created_at']);

    final network = tx['network']?.toString().isNotEmpty == true ? tx['network'].toString() : coin;
    final account = tx['wallet_type']?.toString().isNotEmpty == true ? tx['wallet_type'].toString() : 'Funding Account';
    final remarks = tx['remarks']?.toString().isNotEmpty == true ? tx['remarks'].toString() : '—';

    final orderNo = tx['order_number']?.toString().isNotEmpty == true
        ? tx['order_number'].toString()
        : (tx['trx']?.toString().isNotEmpty == true ? tx['trx'].toString() : '—');
    final address = tx['address']?.toString().isNotEmpty == true
        ? tx['address'].toString()
        : (tx['wallet_address']?.toString().isNotEmpty == true ? tx['wallet_address'].toString() : '—');
    final txHash = tx['transaction_id']?.toString().isNotEmpty == true
        ? tx['transaction_id'].toString()
        : (tx['tx_hash']?.toString().isNotEmpty == true ? tx['tx_hash'].toString() : (tx['trx']?.toString() ?? '—'));

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _isDep ? 'Deposit Details' : 'Withdrawal Details',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: _font, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── BIG AMOUNT + STATUS ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
                      child: Center(
                        child: Text(
                          '${_isDep ? "+ " : "- "}$amtDisplay $coin',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontFamily: _font, fontWeight: FontWeight.w700, height: 1.33),
                        ),
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Circular dot with checkmark — matches web SVG
                          Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                            child: Center(
                              child: CustomPaint(size: const Size(8, 8), painter: _CheckPainter()),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),

                    // ── SUB NOTE ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Text(
                        _isDep
                            ? 'crypto deposited to your Trapix account.'
                            : 'crypto transferred out of Trapix. Please contact the recipient platform for your transaction receipt',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Center(
                        child: Text(
                          _isDep ? "Why hasn't my deposit arrived?" : "Why hasn't my withdrawal arrived?",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _accent, fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33),
                        ),
                      ),
                    ),

                    // ── DIVIDER + ROWS ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Divider(color: Colors.white.withOpacity(0.10), height: 1, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _Row(label: _isDep ? 'Deposit Amount' : 'Withdrawal Amount', value: '$amtDisplay $coin'),
                          _Row(label: 'Fee', value: '$feeDisplay $coin'),
                          _Row(label: 'Time', value: time),
                          _Row(label: 'Network', value: network),
                          _Row(label: _isDep ? 'Account' : 'Withdrawal Account', value: account),
                          _Row(label: 'Remarks', value: remarks, bold: true),
                          _Row(label: 'Order Number', value: _short(orderNo), copyable: true, onCopy: () => _copy(context, orderNo)),
                          _Row(label: 'Address', value: _short(address), copyable: true, bold: true, onCopy: () => _copy(context, address)),
                          _Row(label: 'TxHash', value: _short(txHash), copyable: true, link: true, onCopy: () => _copy(context, txHash)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── BOTTOM BUTTON (fixed) ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    _isDep ? 'Deposit More' : 'Withdraw More',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: _font, fontWeight: FontWeight.w400),
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

// Matches web SVG checkmark: "M3 6.2l2 2 4-4.4"
class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.68)
      ..lineTo(size.width * 0.75, size.height * 0.32);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_) => false;
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool copyable;
  final bool link;
  final VoidCallback? onCopy;

  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
    this.copyable = false,
    this.link = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isDash = value == '—' || value.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label — flexShrink: 0
          Text(label,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33)),
          const SizedBox(width: 12),
          // Value — maxWidth 230, textAlign right, wordBreak break-all
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: _font,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                      height: 1.33,
                      decoration: link && !isDash ? TextDecoration.underline : null,
                    ),
                  ),
                ),
                if (copyable && !isDash) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onCopy,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: _CopyIcon(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Green copy icon matching web SVG
class _CopyIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12, height: 13,
      child: CustomPaint(painter: _CopyPainter()),
    );
  }
}

class _CopyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCFF00)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Front rect: x=3,y=3, w=8,h=9, rx=1
    final front = RRect.fromLTRBR(3, 3, 11, 12, const Radius.circular(1));
    canvas.drawRRect(front, paint);

    // Back path: "M8.5 3V2a1 1 0 0 0-1-1H2a1 1 0 0 0-1 1v6.5a1 1 0 0 0 1 1h1"
    final back = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(8.5, 3)
      ..lineTo(8.5, 2)
      ..arcToPoint(const Offset(7.5, 1), radius: const Radius.circular(1))
      ..lineTo(2, 1)
      ..arcToPoint(const Offset(1, 2), radius: const Radius.circular(1))
      ..lineTo(1, 8.5)
      ..arcToPoint(const Offset(2, 9.5), radius: const Radius.circular(1))
      ..lineTo(3, 9.5);
    canvas.drawPath(path, back);
  }
  @override
  bool shouldRepaint(_) => false;
}
