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

  String get _title => _isDeposit ? 'Deposit Details' : 'Withdrawal Details';

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
    final network = tx['network']?.toString() ?? tx['coin_type']?.toString() ?? '---';
    final account = tx['wallet_type']?.toString().isNotEmpty == true
        ? tx['wallet_type'].toString()
        : 'Funding Account';
    final remarks = tx['remarks']?.toString().isNotEmpty == true ? tx['remarks'].toString() : '---';
    final orderNo = tx['order_number']?.toString() ?? tx['trx']?.toString() ?? '---';
    final address = tx['address']?.toString() ?? tx['wallet_address']?.toString() ?? '---';
    final txHash = tx['transaction_id']?.toString() ?? tx['tx_hash']?.toString() ?? tx['trx']?.toString() ?? '---';

    final prefix = _isDeposit ? '+' : '-';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                    ),
                  ),
                  Text(_title, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: _font, fontWeight: FontWeight.w700, height: 1.50)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    // Big amount
                    Text(
                      '$prefix $amount $coin',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontFamily: _font, fontWeight: FontWeight.w700, height: 1.33),
                    ),
                    const SizedBox(height: 8),
                    // Status badge
                    Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33)),
                    const SizedBox(height: 24),
                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _isDeposit
                            ? 'crypto received into Trapix. Check your wallet for confirmation.'
                            : 'crypto transferred out of Trapix. Please contact the recipient platform for your transaction receipt',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33),
                      ),
                    ),
                    if (!_isDeposit) ...[
                      const SizedBox(height: 12),
                      Text(
                        "Why hasn't my withdrawal arrived?",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _accent, fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(color: Colors.white.withOpacity(0.10), height: 1),
                    ),
                    const SizedBox(height: 16),
                    // Detail rows
                    _row(context, _isDeposit ? 'Deposit Amount' : 'Withdrawal Amount', '$amount $coin'),
                    _row(context, 'Fee', '$fee $coin'),
                    _row(context, 'Time', time),
                    _row(context, 'Network', network),
                    _row(context, _isDeposit ? 'Deposit Account' : 'Withdrawal Account', account),
                    _row(context, 'Remarks', remarks),
                    _copyRow(context, 'Order Number', orderNo),
                    _copyRow(context, 'Address', address),
                    _copyRow(context, 'TxHash', txHash, underline: true),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    _isDeposit ? 'Deposit More' : 'Withdraw More',
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

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33)),
          const Spacer(),
          Flexible(
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33)),
          ),
        ],
      ),
    );
  }

  Widget _copyRow(BuildContext context, String label, String value, {bool underline = false}) {
    final display = value.length > 20 ? '${value.substring(0, 8)}...${value.substring(value.length - 6)}' : value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 12, fontFamily: _font, fontWeight: FontWeight.w400, height: 1.33)),
          const Spacer(),
          GestureDetector(
            onTap: () => _copy(context, value),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    display,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: _font,
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                      decoration: underline ? TextDecoration.underline : null,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.copy, size: 12, color: Colors.white54),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
