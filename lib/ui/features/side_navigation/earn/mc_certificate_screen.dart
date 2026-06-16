import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class McCertificateScreen extends StatefulWidget {
  final Map<String, dynamic> stake;
  const McCertificateScreen({super.key, required this.stake});

  @override
  State<McCertificateScreen> createState() => _McCertificateScreenState();
}

class _McCertificateScreenState extends State<McCertificateScreen> {
  late final WebViewController _controller;
  bool _loaded = false;
  double _certHeight = 300;

  @override
  void initState() {
    super.initState();
    final html = _buildCertHtml(widget.stake);
    final encoded = base64Encode(utf8.encode(html));
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A1A0A))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) async {
          // Get scaled height from JS
          final result = await _controller.runJavaScriptReturningResult(
            'document.documentElement.getBoundingClientRect().height'
          );
          final h = double.tryParse(result.toString()) ?? 300;
          if (mounted) setState(() { _certHeight = h; _loaded = true; });
        },
      ))
      ..loadRequest(Uri.parse('data:text/html;base64,$encoded'));
  }

  String get _certNo => widget.stake['cert_no'] ?? 'TRPX-00000000';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Staking Certificate',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _certNo));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Certificate No. copied'),
                        backgroundColor: Color(0xFF1A1A1A),
                        duration: Duration(seconds: 2),
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
                      child: const Row(children: [
                        Icon(Icons.copy, color: Color(0xFFB8960C), size: 14),
                        SizedBox(width: 4),
                        Text('Copy No.', style: TextStyle(color: Color(0xFFB8960C), fontSize: 12)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            // WebView certificate — fixed height based on scaled cert
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Stack(
                children: [
                  Container(
                    height: _certHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFB8960C).withValues(alpha: 0.3)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: WebViewWidget(controller: _controller),
                  ),
                  if (!_loaded)
                    SizedBox(
                      height: _certHeight,
                      child: const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00))),
                    ),
                ],
              ),
            ),
            const Spacer(),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

String _buildCertHtml(Map<String, dynamic> s) {
  final certNo = s['cert_no'] ?? 'TRPX-00000000';
  final planName = s['plan_name'] ?? '';
  final symbol = s['coin_symbol'] ?? '';
  final coinName = s['coin_name'] ?? '';
  final amount = double.tryParse(s['amount']?.toString() ?? '0') ?? 0;
  final dailyRate = double.tryParse(s['daily_rate']?.toString() ?? '0') ?? 0;
  final totalReturn = s['total_return']?.toString() ?? '';
  final durationDays = s['duration_days'] ?? 0;
  final startDate = s['start_date'] ?? '';
  final endDate = s['end_date'] ?? '';
  final planType = s['plan_type'] ?? 1;
  final userName = s['user_name'] ?? 'Valued Staker';
  final stakingType = planType == 2 ? 'Locked Staking' : planType == 3 ? 'Long-Term' : 'Flexible';
  final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=80x80&data=TRAPIX-CERT-$certNo';

  final totalReturnRow = (totalReturn.isNotEmpty && totalReturn != 'null')
      ? '<div class="dr"><span class="dl">Total Return</span><span class="dv gold">$totalReturn%</span></div>'
      : '';
  final maturityRow = endDate.isNotEmpty
      ? '<div class="dr"><span class="dl">Maturity Date</span><span class="dv">$endDate</span></div>'
      : '';
  final durationRow = durationDays > 0
      ? '<div class="dr"><span class="dl">Duration</span><span class="dv">$durationDays Days</span></div>'
      : '';

  return '''<!DOCTYPE html><html><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0"/>
<title>Staking Certificate - $certNo</title>
<style>
@import url("https://fonts.googleapis.com/css2?family=Cinzel:wght@400;700;900&family=Inter:wght@400;600;700&display=swap");
*{margin:0;padding:0;box-sizing:border-box;}
body{width:1122px;height:794px;overflow:hidden;font-family:"Inter",sans-serif;}
.cert{width:1122px;height:794px;position:relative;background:linear-gradient(135deg,#0a1a0a 0%,#0d2010 30%,#091505 60%,#0a1a0a 100%);color:#fff;display:flex;flex-direction:column;}
.bo{position:absolute;inset:8px;border:2px solid #b8960c;border-radius:4px;pointer-events:none;}
.bi{position:absolute;inset:14px;border:1px solid rgba(184,150,12,0.4);border-radius:3px;pointer-events:none;}
.c{position:absolute;width:55px;height:55px;}
.ctl{top:8px;left:8px;border-top:3px solid #b8960c;border-left:3px solid #b8960c;}
.ctr{top:8px;right:8px;border-top:3px solid #b8960c;border-right:3px solid #b8960c;}
.cbl{bottom:8px;left:8px;border-bottom:3px solid #b8960c;border-left:3px solid #b8960c;}
.cbr{bottom:8px;right:8px;border-bottom:3px solid #b8960c;border-right:3px solid #b8960c;}
.hdr{display:flex;align-items:center;justify-content:center;gap:20px;padding:22px 60px 14px;border-bottom:1px solid rgba(184,150,12,0.3);}
.divg{width:120px;height:2px;background:linear-gradient(90deg,transparent,#b8960c,transparent);}
.logo-w{display:flex;align-items:center;gap:12px;}
.logo-img{width:44px;height:44px;object-fit:contain;}
.brand{font-family:"Cinzel",serif;font-size:26px;font-weight:900;color:#ccff00;letter-spacing:3px;}
.brand-s{font-family:"Cinzel",serif;font-size:10px;color:#b8960c;letter-spacing:4px;margin-top:-4px;}
.ts{text-align:center;padding:12px 60px 8px;}
.mt{font-family:"Cinzel",serif;font-size:28px;font-weight:900;color:#b8960c;letter-spacing:4px;text-shadow:0 0 30px rgba(184,150,12,0.5);}
.st{font-size:10px;color:rgba(255,255,255,0.5);letter-spacing:3px;margin-top:3px;}
.pres{font-size:11px;color:rgba(255,255,255,0.6);margin-top:7px;}
.uname{font-family:"Cinzel",serif;font-size:20px;font-weight:700;color:#fff;margin-top:3px;letter-spacing:2px;}
.pl{font-size:11px;color:rgba(255,255,255,0.6);margin-top:4px;}
.pl span{color:#ccff00;font-weight:700;}
.body{display:grid;grid-template-columns:1fr 1fr 1fr;gap:0;flex:1;padding:8px 36px 12px;}
.sec{padding:0 14px;}
.sec+.sec{border-left:1px solid rgba(184,150,12,0.2);}
.sth{font-size:9px;font-weight:700;letter-spacing:2px;color:#b8960c;text-transform:uppercase;margin-bottom:8px;display:flex;align-items:center;gap:5px;}
.sth::before,.sth::after{content:"";flex:1;height:1px;background:rgba(184,150,12,0.3);}
.dr{display:flex;justify-content:space-between;align-items:center;padding:4px 0;border-bottom:1px solid rgba(255,255,255,0.05);}
.dl{font-size:9.5px;color:rgba(255,255,255,0.45);}
.dv{font-size:10.5px;font-weight:700;color:#fff;}
.dv.gold{color:#b8960c;}
.dv.green{color:#ccff00;}
.sbadge{display:inline-flex;align-items:center;gap:4px;background:rgba(0,176,82,0.15);border:1px solid #00b052;border-radius:20px;padding:2px 8px;font-size:9px;color:#00b052;font-weight:700;}
.qrw{display:flex;flex-direction:column;align-items:center;gap:6px;margin-top:10px;}
.qrb{width:88px;height:88px;background:#fff;padding:6px;border-radius:4px;}
.qrb img{width:76px;height:76px;}
.decl{font-size:9px;color:rgba(255,255,255,0.4);line-height:1.65;}
.ftr{text-align:center;padding:6px 60px 18px;border-top:1px solid rgba(184,150,12,0.3);}
.fb{font-family:"Cinzel",serif;font-size:13px;font-weight:700;color:#b8960c;letter-spacing:4px;}
.ft{font-size:8px;color:rgba(255,255,255,0.3);letter-spacing:2px;margin-top:2px;}
.seal{position:absolute;right:50px;bottom:100px;width:88px;height:88px;border-radius:50%;border:3px solid #b8960c;display:flex;flex-direction:column;align-items:center;justify-content:center;background:radial-gradient(circle,#0a1a0a,#152a10);box-shadow:0 0 20px rgba(184,150,12,0.4);}
.seal-t{font-family:"Cinzel",serif;font-size:7.5px;color:#b8960c;letter-spacing:1px;text-align:center;font-weight:700;}
.seal-l{font-size:20px;color:#ccff00;font-weight:900;font-family:"Cinzel",serif;}
</style>
<script>
window.onload = function() {
  var vw = window.innerWidth || document.documentElement.clientWidth;
  var scale = vw / 1122;
  document.body.style.transform = 'scale(' + scale + ')';
  document.body.style.transformOrigin = 'top left';
  document.body.style.width = '1122px';
  document.body.style.height = '794px';
  document.body.style.overflow = 'hidden';
  document.documentElement.style.width = vw + 'px';
  document.documentElement.style.height = (794 * scale) + 'px';
  document.documentElement.style.overflow = 'hidden';
};
</script>
</head><body>
<div class="cert">
  <div class="bo"></div><div class="bi"></div>
  <div class="c ctl"></div><div class="c ctr"></div><div class="c cbl"></div><div class="c cbr"></div>
  <div class="hdr">
    <div class="divg"></div>
    <div class="logo-w">
      <img src="https://trapix.com/green_logo.png" class="logo-img" onerror="this.style.display='none'"/>
      <div><div class="brand">TRAPIX</div><div class="brand-s">EXCHANGE</div></div>
    </div>
    <div class="divg"></div>
  </div>
  <div class="ts">
    <div class="mt">DIGITAL STAKING CERTIFICATE</div>
    <div class="st">★ CERTIFICATE OF DIGITAL STAKING PARTICIPATION ★</div>
    <div class="pres">This certificate is proudly presented to</div>
    <div class="uname">$userName</div>
    <div class="pl">for successfully participating in the <span>$planName</span> staking program offered by <span>Trapix Exchange</span>.</div>
  </div>
  <div class="body">
    <div class="sec">
      <div class="sth">🌸 Certificate Details 🌸</div>
      <div class="dr"><span class="dl">Certificate No.</span><span class="dv gold">$certNo</span></div>
      <div class="dr"><span class="dl">Asset</span><span class="dv">$symbol $coinName</span></div>
      <div class="dr"><span class="dl">Staking Product</span><span class="dv">$planName</span></div>
      <div class="dr"><span class="dl">Staked Amount</span><span class="dv green">${amount.toStringAsFixed(2)} $symbol</span></div>
      <div class="dr"><span class="dl">Daily Rate</span><span class="dv gold">${dailyRate.toStringAsFixed(2)}% / Day</span></div>
      $totalReturnRow
      <div class="dr"><span class="dl">Type</span><span class="dv">$stakingType</span></div>
    </div>
    <div class="sec">
      <div class="sth">📅 Important Dates</div>
      <div class="dr"><span class="dl">Start Date</span><span class="dv">$startDate</span></div>
      $durationRow
      $maturityRow
      <div class="dr"><span class="dl">Status</span><span class="dv"><span class="sbadge">● Active</span></span></div>
      <div class="qrw">
        <div class="qrb"><img src="$qrUrl" alt="QR"/></div>
        <div style="font-size:8px;color:rgba(255,255,255,0.3);letter-spacing:1px;">SCAN TO VERIFY</div>
      </div>
    </div>
    <div class="sec">
      <div class="sth">📋 Declaration</div>
      <p class="decl">This certificate acknowledges the holder's enrollment in the designated Trapix staking plan and serves as an official record of participation. All rewards remain subject to Trapix Exchange terms and operational policies.</p>
      <div style="margin-top:10px;">
        <div class="sth">🛡 Verification</div>
        <div class="dr"><span class="dl">Exchange</span><span class="dv">Trapix Exchange</span></div>
        <div class="dr"><span class="dl">Issued On</span><span class="dv">$startDate</span></div>
        <div class="dr"><span class="dl">Issued By</span><span class="dv gold">Trapix Exchange</span></div>
        <div class="dr"><span class="dl">Status</span><span class="dv green">✓ Valid</span></div>
      </div>
    </div>
  </div>
  <div class="seal"><div class="seal-l">T</div><div class="seal-t">TRAPIX<br/>EXCHANGE<br/>VERIFIED</div></div>
  <div class="ftr"><div class="fb">TRAPIX EXCHANGE</div><div class="ft">TRADE RESPONSIBLY · STAKE SECURELY · GROW WITH TRAPIX</div></div>
</div>
</body></html>''';
}
