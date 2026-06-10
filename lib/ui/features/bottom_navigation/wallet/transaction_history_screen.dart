import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/history.dart';
import 'package:tradexpro_flutter/data/models/response.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';

const Color _bg = Color(0xFF111111);
const Color _green = Color(0xFF4ED78E);
const Color _red = Color(0xFFD73C3C);
const Color _yellow = Color(0xFFE0B341);
const Color _accent = Color(0xFFCCFF00);
const String _font = 'DMSans';

class TransactionHistoryScreen extends StatefulWidget {
  final String initialTab;
  const TransactionHistoryScreen({super.key, this.initialTab = 'deposit'});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late String _tab;
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _load(_tab, 1, true);
  }

  Map<String, String> _authHeaders() {
    final token = GetStorage().read(PreferenceKey.accessToken) ?? '';
    final type = GetStorage().read(PreferenceKey.accessType) ?? 'Bearer';
    final secret = dotenv.env[EnvKeyValue.kApiSecret] ?? '';
    return {
      'Accept': 'application/json',
      'userapisecret': secret,
      if (token.isNotEmpty) 'Authorization': '$type $token',
    };
  }

  Future<void> _load(String tab, int pg, bool replace) async {
    if (pg == 1) setState(() => _loading = true);
    else setState(() => _loadingMore = true);

    try {
      List<Map<String, dynamic>> list = [];

      if (tab == 'deposit' || tab == 'withdraw') {
        // Use APIRepository which handles all auth headers correctly
        final histType = tab == 'withdraw' ? HistoryType.withdraw : HistoryType.deposit;
        final resp = await APIRepository().getActivityList(pg, histType, isFiat: false);
        if (resp.success) {
          try {
            final hResp = HistoryResponse.fromJson(resp.data);
            final data = hResp.histories?.data;
            if (data != null) {
              list = data.map<Map<String, dynamic>>((h) => {
                '_type': tab,
                'coin_type': h.coinType ?? 'USDT',
                'amount': h.amount?.toString() ?? '0',
                'status': h.status?.toString() ?? '0',
                'created_at': h.createdAt?.toIso8601String() ?? '',
              }).toList();
            }
          } catch (_) {}
        }
        _hasMore = list.length >= 25;
      } else if (tab == 'swap') {
        final res = await http.get(
          Uri.parse('${APIURLConstants.baseUrl}/api/v1/swap/history'),
          headers: _authHeaders(),
        );
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final data = body['data'];
          if (data is List) list = data.map<Map<String, dynamic>>((e) => {...Map<String, dynamic>.from(e), '_type': 'swap'}).toList();
        }
        _hasMore = false;
      } else if (tab == 'transfer') {
        final res = await http.get(
          Uri.parse('${APIURLConstants.baseUrl}/api/v1/transfer-history?page=$pg&per_page=25'),
          headers: _authHeaders(),
        );
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final data = body['data'];
          if (data is List) list = data.map<Map<String, dynamic>>((e) => {...Map<String, dynamic>.from(e), '_type': 'transfer'}).toList();
        }
        _hasMore = list.length >= 25;
      }

      setState(() {
        _rows = replace ? list : [..._rows, ...list];
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() { _loading = false; _loadingMore = false; });
    }
  }

  void _switchTab(String tab) {
    setState(() { _tab = tab; _rows = []; _page = 1; _hasMore = true; });
    _load(tab, 1, true);
  }

  String _statusLabel(dynamic status) {
    final raw = status?.toString().toLowerCase() ?? '';
    if (['success', 'completed', '1', 'approved', 'confirmed'].contains(raw)) return 'Success';
    if (['pending', '0', 'processing', '2', 'in_progress'].contains(raw)) return 'Pending';
    return 'Failed';
  }

  Color _statusColor(String label) {
    if (label == 'Success') return _green;
    if (label == 'Pending') return _yellow;
    return _red;
  }

  String _formatDate(dynamic raw) {
    try {
      if (raw == null || raw.toString().isEmpty) return '';
      final dt = DateTime.parse(raw.toString()).toLocal();
      return formatDate(dt, format: "d MMM ''yy, hh:mm a");
    } catch (_) { return raw?.toString() ?? ''; }
  }

  String _fmt(double v, {int decimals = 8}) {
    if (v == v.truncateToDouble()) return v.toStringAsFixed(2);
    final s = v.toStringAsFixed(decimals).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['deposit', 'withdraw', 'transfer', 'swap'];
    const tabLabels = ['Deposit', 'Withdraw', 'Transfer', 'Swap'];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  const Text('Assets', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _font)),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: List.generate(tabs.length, (i) => Padding(
                  padding: EdgeInsets.only(right: i < tabs.length - 1 ? 22 : 0),
                  child: GestureDetector(
                    onTap: () => _switchTab(tabs[i]),
                    child: Text(
                      tabLabels[i],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _tab == tabs[i] ? FontWeight.w700 : FontWeight.w400,
                        color: _tab == tabs[i] ? Colors.white : Colors.white.withOpacity(0.5),
                        fontFamily: _font,
                      ),
                    ),
                  ),
                )),
              ),
            ),

            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
                  : _rows.isEmpty
                      ? Center(child: Text('No $_tab history yet', style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: _font)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          itemCount: _rows.length + (_hasMore && _tab != 'swap' ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _rows.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: _loadingMore
                                      ? const CircularProgressIndicator(color: _accent, strokeWidth: 2)
                                      : GestureDetector(
                                          onTap: () {
                                            final np = _page + 1;
                                            setState(() => _page = np);
                                            _load(_tab, np, false);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1a1a1a),
                                              border: Border.all(color: const Color(0xFF2a2a2a)),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Text('Load more', style: TextStyle(color: _green, fontWeight: FontWeight.w700, fontSize: 13, fontFamily: _font)),
                                          ),
                                        ),
                                ),
                              );
                            }
                            return _buildRow(_rows[i]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> tx) {
    final type = tx['_type']?.toString() ?? '';
    final isSwap = type == 'swap';
    final isTransfer = type == 'transfer';
    final isDep = type == 'deposit';

    final iconBg = (isTransfer || isSwap)
        ? _accent.withOpacity(0.18)
        : isDep ? const Color(0xFF015629).withOpacity(0.4) : const Color(0xFF920000).withOpacity(0.5);
    final iconColor = (isTransfer || isSwap) ? _accent : isDep ? _green : _red;

    // Title line
    String title;
    if (isSwap) title = '${tx['from_coin']} → ${tx['to_coin']}';
    else if (isTransfer) title = tx['direction']?.toString().isNotEmpty == true ? tx['direction'].toString() : 'Transfer';
    else title = tx['coin_type']?.toString() ?? 'USDT';

    // Subtitle
    String? subtitle;
    if (isSwap) {
      final fee = double.tryParse(tx['fee_amount']?.toString() ?? '0') ?? 0;
      subtitle = 'Fee ${_fmt(fee)} ${tx['from_coin']}';
    } else if (isTransfer) {
      subtitle = tx['coin_type']?.toString() ?? 'USDT';
    }

    // Amount
    String amountTop;
    String? amountBottom;
    if (isSwap) {
      final toAmt = double.tryParse(tx['to_amount']?.toString() ?? '0') ?? 0;
      final fromAmt = double.tryParse(tx['from_amount']?.toString() ?? '0') ?? 0;
      amountTop = '+${_fmt(toAmt)} ${tx['to_coin']}';
      amountBottom = '-${_fmt(fromAmt)} ${tx['from_coin']}';
    } else if (isTransfer) {
      final amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
      amountTop = '${_fmt(amt)} ${tx['coin_type'] ?? 'USDT'}';
    } else {
      final amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
      amountTop = '\$${amt.toStringAsFixed(2)}';
    }

    final statusLabel = (isTransfer || isSwap) ? 'Success' : _statusLabel(tx['status']);
    final statusColor = _statusColor(statusLabel);
    final date = _formatDate(tx['created_at']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(
              (isTransfer || isSwap) ? Icons.swap_horiz : isDep ? Icons.arrow_downward : Icons.arrow_upward,
              size: 14, color: iconColor,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _font, height: 1.5)),
                if (subtitle != null) Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontFamily: _font)),
                Text(date, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: _font)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amountTop, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: _font, height: 1.5)),
              if (amountBottom != null) Text(amountBottom, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11, fontFamily: _font)),
              Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontFamily: _font)),
            ],
          ),
        ],
      ),
    );
  }
}
