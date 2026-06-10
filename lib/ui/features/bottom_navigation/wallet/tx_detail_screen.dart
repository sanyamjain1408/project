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

  bool get _isDeposit => tx['_type'] == 'deposit';

  String _fmt(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '0') ?? 0;
    if (d == d.truncateToDouble()) return d.toStringAsFixed(2);
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
    if (raw == null || raw.toString().isEmpty) return '---';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
    } catch (_) { return raw.toString(); }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _copy(BuildContext context, String text) {
    if (text == '---') return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1), backgroundColor: Color(0xFF222222)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coin = tx['coin_type']?.toString() ?? 'USDT';
    final amount = _fmt(tx['amount']);
    final fee = _fmt(tx['fees'] ?? tx['fee'] ?? 0);
    final statusLabel = _statusLabel(tx['status']);
    final statusColor = _statusColor(statusLabel);
    final time = _formatDate(tx['created_at']);
    final network = tx['network']?.toString().isNotEmpty == true
        ? tx['network'].toString()
        : coin;
    final account = tx['wallet_type']?.toString().isNotEmpty == true
        ? tx['wallet_type'].toString()
        : 'Funding Account';
    final remarks = tx['remarks']?.toString().isNotEmpty == true ? tx['remarks'].toString() : '---';
    final orderNo = tx['order_number']?.toString().isNotEmpty == true
        ? tx['order_number'].toString()
        : (tx['trx']?.toString().isNotEmpty == true ? tx['trx'].toString() : '---');
    final address = tx['address']?.toString().isNotEmpty == true
        ? tx['address'].toString()
        : (tx['wallet_address']?.toString().isNotEmpty == true ? tx['wallet_address'].toString() : '---');
    final txHash = tx['transaction_id']?.toString().isNotEmpty == true
        ? tx['transaction_id'].toString()
        : (tx['tx_hash']?.toString().isNotEmpty == true ? tx['tx_hash'].toString() : (tx['trx']?.toString() ?? '---'));

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER (top: 64 in Figma, SafeArea handles status bar) ───────
            SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 20,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                    ),
                  ),
                  Text(
                    _isDeposit ? 'Deposit Details' : 'Withdrawal Details',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: _font, fontWeight: FontWeight.w700, height: 1.50),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── AMOUNT (top: 108) ──────────────────────────────────
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '- $amount $coin',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 30, fontFamily: _font, fontWeight: FontWeight.w700, height: 1.33),
                      ),
                    ),
                    // ── STATUS (top: 153) ──────────────────────────────────
                    const SizedBox(height: 8),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: statusColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: statusColor, fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33),
                          ),
                        ],
                      ),
                    ),
                    // ── DESCRIPTION (top: 189) ─────────────────────────────
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Text(
                          'crypto transferred out of Trapix. Please contact the recipient platform for your transaction receipt',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33),
                        ),
                      ),
                    ),
                    // ── WHY LINK (top: 231) ────────────────────────────────
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        "Why hasn't my withdrawal arrived?",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _accent, fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33),
                      ),
                    ),
                    // ── DIVIDER (top: 267) ─────────────────────────────────
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(color: Colors.white.withOpacity(0.10), height: 1, thickness: 1),
                    ),
                    // ── DETAIL ROWS ────────────────────────────────────────
                    const SizedBox(height: 20),
                    _row(context, 'Withdrawal Amount', '$amount $coin'),
                    _row(context, 'Fee', '$fee $coin'),
                    _row(context, 'Time', time),
                    _row(context, 'Network', network),
                    _row(context, 'Withdrawal Account', account),
                    _row(context, 'Remarks', remarks, bold: remarks != '---'),
                    _copyRow(context, 'Order Number', orderNo),
                    _copyRow(context, 'Address', address),
                    _copyRow(context, 'TxHash', txHash, underline: true),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── BOTTOM BUTTON (top: 804) ───────────────────────────────────
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
                    _isDeposit ? 'Deposit Stats' : 'Withdraw Stats',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.50),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
            style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33)),
          const Spacer(),
          Flexible(
            child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: _font, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, height: 1.33)),
          ),
        ],
      ),
    );
  }

  Widget _copyRow(BuildContext context, String label, String value, {bool underline = false}) {
    final isDash = value == '---';
    // Truncate long values: show first 6 ... last 6
    String display = value;
    if (!isDash && value.length > 16) {
      display = '${value.substring(0, 6)}...${value.substring(value.length - 6)}';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
            style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33)),
          const Spacer(),
          GestureDetector(
            onTap: isDash ? null : () => _copy(context, value),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  display,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: _font,
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                    decoration: underline && !isDash ? TextDecoration.underline : null,
                  ),
                ),
                const SizedBox(width: 5),
                if (!isDash) const Icon(Icons.copy_outlined, size: 13, color: Colors.white54),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
