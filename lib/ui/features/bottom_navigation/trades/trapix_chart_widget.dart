import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TrapixChartWidget extends StatefulWidget {
  final String symbol;
  final double height;

  const TrapixChartWidget({
    super.key,
    required this.symbol,
    this.height = 420,
  });

  @override
  State<TrapixChartWidget> createState() => _TrapixChartWidgetState();
}

class _TrapixChartWidgetState extends State<TrapixChartWidget> {
  late WebViewController _controller;
  bool _isLoading = true;
  String _currentInterval = '15m';
  Timer? _pollTimer;
  List<dynamic> _candles = [];
  bool _chartReady = false;
  // Paths to files written in temp dir
  String? _lwcJsPath;   // lightweight-charts.js
  String? _htmlPath;    // chart.html (references lwc via file:// src)

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
    _init();
  }

  @override
  void didUpdateWidget(covariant TrapixChartWidget old) {
    super.didUpdateWidget(old);
    if (old.symbol != widget.symbol) {
      _pollTimer?.cancel();
      _candles = [];
      _chartReady = false;
      _currentInterval = '15m';
      _reloadHtmlForSymbol();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // Write LWC JS and HTML shell to temp dir, then load HTML via file://.
  // Splitting them means the HTML file has a <script src="file://...lwc.js">
  // so Android WebView loads it from local disk — no string interpolation of 158KB JS.
  Future<void> _init() async {
    final lwcJs = await rootBundle.loadString('assets/lightweight-charts.js');
    final dir = await getTemporaryDirectory();

    // Write LWC library as a standalone .js file
    final lwcFile = File('${dir.path}/lwc.js');
    await lwcFile.writeAsString(lwcJs, flush: true);
    _lwcJsPath = lwcFile.path;

    // Write HTML that <script src>s the LWC file
    await _writeHtmlFile(widget.symbol);

    if (!mounted) return;
    _loadChart();
  }

  Future<void> _writeHtmlFile(String symbol) async {
    final dir = await getTemporaryDirectory();
    final sym = symbol
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    final lwcSrc = 'file://$_lwcJsPath';

    final html = '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:100%;height:100%;background:#0b0b0b;color:#d1d4dc;overflow:hidden;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
#root{display:flex;flex-direction:column;height:100%}
#interval-bar{display:flex;align-items:center;gap:4px;padding:6px 8px;background:#0b0b0b;border-bottom:1px solid #1a1a1a;flex-shrink:0;overflow-x:auto;scrollbar-width:none}
#interval-bar::-webkit-scrollbar{display:none}
.iv-label{font-size:11px;color:#8a8f9a;font-weight:700;flex-shrink:0;margin-right:2px}
.iv-btn{background:transparent;border:none;color:#8a8f9a;font-size:12px;padding:4px 8px;cursor:pointer;border-radius:4px;white-space:nowrap;font-weight:500}
.iv-btn.active{background:#2bc295;color:#000;font-weight:700}
.iv-divider{width:1px;height:14px;background:#2a2a2a;margin:0 4px;flex-shrink:0}
.ind-btn{background:transparent;border:1px solid #2a2a2a;color:#8a8f9a;font-size:10px;padding:2px 6px;cursor:pointer;border-radius:4px;white-space:nowrap;font-weight:500}
.ind-btn.active{background:#1a1a1a;color:#d1d4dc;border-color:#2bc295}
#chart-wrap{display:flex;flex:1;overflow:hidden;position:relative}
#chart{flex:1;position:relative}
#bottom-bar{display:flex;align-items:center;justify-content:space-between;padding:3px 8px;background:#0b0b0b;border-top:1px solid #1a1a1a;flex-shrink:0}
.rng-btn{background:transparent;border:none;color:#8a8f9a;font-size:11px;padding:3px 6px;cursor:pointer;border-radius:4px}
.rng-btn.active{background:#1a1a1a;color:#d1d4dc}
#utc-clock{font-size:10px;color:#8a8f9a;font-family:monospace}
.scale-btn{background:transparent;border:none;color:#8a8f9a;font-size:11px;padding:3px 6px;cursor:pointer;border-radius:4px}
.scale-btn.active{background:#1a1a1a;color:#d1d4dc}
</style>
</head>
<body>
<div id="root">
  <div id="interval-bar">
    <span class="iv-label" style="color:#2bc295;font-size:12px;margin-right:4px">$sym</span>
    <span class="iv-label">Time</span>
    <button class="iv-btn active" data-iv="15m" onclick="changeInterval(this)">15m</button>
    <button class="iv-btn" data-iv="1h"  onclick="changeInterval(this)">1h</button>
    <button class="iv-btn" data-iv="4h"  onclick="changeInterval(this)">4h</button>
    <button class="iv-btn" data-iv="1d"  onclick="changeInterval(this)">1d</button>
    <button class="iv-btn" data-iv="1w"  onclick="changeInterval(this)">1w</button>
    <div class="iv-divider"></div>
    <button class="ind-btn active" data-ind="VOL" onclick="toggleInd(this)">VOL</button>
    <button class="ind-btn" data-ind="MA"   onclick="toggleInd(this)">MA</button>
    <button class="ind-btn" data-ind="EMA"  onclick="toggleInd(this)">EMA</button>
    <button class="ind-btn" data-ind="BOLL" onclick="toggleInd(this)">BOLL</button>
  </div>
  <div id="chart-wrap"><div id="chart"></div></div>
  <div id="bottom-bar">
    <div style="display:flex;gap:2px">
      <button class="rng-btn active" onclick="setRng(this,'1d')">1d</button>
      <button class="rng-btn" onclick="setRng(this,'5d')">5d</button>
      <button class="rng-btn" onclick="setRng(this,'1m')">1m</button>
      <button class="rng-btn" onclick="setRng(this,'3m')">3m</button>
      <button class="rng-btn" onclick="setRng(this,'1y')">1y</button>
    </div>
    <div id="utc-clock"></div>
    <div style="display:flex;gap:2px">
      <button class="scale-btn active" onclick="setScale(this,'normal')">auto</button>
      <button class="scale-btn" onclick="setScale(this,'log')">log</button>
    </div>
  </div>
</div>
<script src="$lwcSrc"></script>
<script>
var chart,candleSeries,volumeSeries,ma7,ma25,ema9,bollUp,bollMid,bollLow;
var allCandles=[];
var activeInds={VOL:true,MA:false,EMA:false,BOLL:false};

function initChart(){
  var el=document.getElementById('chart');
  chart=LightweightCharts.createChart(el,{
    width:el.clientWidth,height:el.clientHeight,
    layout:{background:{color:'#0b0b0b'},textColor:'#d1d4dc'},
    grid:{vertLines:{color:'#1a1a1a'},horzLines:{color:'#1a1a1a'}},
    crosshair:{mode:1},
    rightPriceScale:{borderColor:'#1a1a1a'},
    timeScale:{borderColor:'#1a1a1a',timeVisible:true,secondsVisible:false},
  });
  candleSeries=chart.addCandlestickSeries({
    upColor:'#2bc295',downColor:'#ff4747',
    borderUpColor:'#2bc295',borderDownColor:'#ff4747',
    wickUpColor:'#2bc295',wickDownColor:'#ff4747',
  });
  volumeSeries=chart.addHistogramSeries({
    priceFormat:{type:'volume'},priceScaleId:'vol',visible:activeInds.VOL,
  });
  volumeSeries.priceScale().applyOptions({scaleMargins:{top:0.8,bottom:0}});
  ma7 =chart.addLineSeries({color:'#f0b90b',lineWidth:1,title:'MA7', visible:activeInds.MA});
  ma25=chart.addLineSeries({color:'#e02f96',lineWidth:1,title:'MA25',visible:activeInds.MA});
  ema9=chart.addLineSeries({color:'#2bc295',lineWidth:1,title:'EMA9',visible:activeInds.EMA});
  bollUp =chart.addLineSeries({color:'#9b2fe0',lineWidth:1,title:'BB+',visible:activeInds.BOLL});
  bollMid=chart.addLineSeries({color:'#2962ff',lineWidth:1,title:'BBM',visible:activeInds.BOLL});
  bollLow=chart.addLineSeries({color:'#9b2fe0',lineWidth:1,title:'BB-',visible:activeInds.BOLL});
  new ResizeObserver(function(){
    if(chart) chart.applyOptions({width:el.clientWidth,height:el.clientHeight});
  }).observe(el);
  ChartReady.postMessage('ready');
}

function calcSMA(data,p){
  var r=[];
  for(var i=p-1;i<data.length;i++){
    var s=0;for(var j=0;j<p;j++) s+=data[i-j].close;
    r.push({time:data[i].time,value:s/p});
  }
  return r;
}
function calcEMA(data,p){
  if(!data.length) return [];
  var r=[],k=2/(p+1),prev=data[0].close;
  for(var i=0;i<data.length;i++){
    var v=data[i].close*k+prev*(1-k);
    r.push({time:data[i].time,value:v});prev=v;
  }
  return r;
}
function calcBOLL(data,p,m){
  var up=[],mid=[],low=[];
  for(var i=p-1;i<data.length;i++){
    var s=0;for(var j=0;j<p;j++) s+=data[i-j].close;
    var mn=s/p,vs=0;
    for(var j=0;j<p;j++) vs+=Math.pow(data[i-j].close-mn,2);
    var sd=Math.sqrt(vs/p);
    mid.push({time:data[i].time,value:mn});
    up.push({time:data[i].time,value:mn+m*sd});
    low.push({time:data[i].time,value:mn-m*sd});
  }
  return{up:up,mid:mid,low:low};
}
function updateIndicators(candles){
  if(!candles.length) return;
  var closes=candles.map(function(c){return{time:c.time,close:+c.close};});
  if(ma7)  ma7.setData(calcSMA(closes,7));
  if(ma25) ma25.setData(calcSMA(closes,25));
  if(ema9) ema9.setData(calcEMA(closes,9));
  if(bollUp){var b=calcBOLL(closes,20,2);bollUp.setData(b.up);bollMid.setData(b.mid);bollLow.setData(b.low);}
}
function setChartData(candles){
  if(!chart||!candles||!candles.length) return;
  allCandles=candles;
  candleSeries.setData(candles.map(function(c){return{time:+c.time,open:+c.open,high:+c.high,low:+c.low,close:+c.close};}));
  volumeSeries.setData(candles.map(function(c){return{time:+c.time,value:+c.volume,color:+c.close>=+c.open?'rgba(43,194,149,0.45)':'rgba(255,71,71,0.45)'};}));
  updateIndicators(allCandles);
  chart.timeScale().fitContent();
}
function updateChartData(candles){
  if(!chart||!candles||!candles.length) return;
  for(var i=0;i<candles.length;i++){
    var c=candles[i];
    candleSeries.update({time:+c.time,open:+c.open,high:+c.high,low:+c.low,close:+c.close});
    volumeSeries.update({time:+c.time,value:+c.volume,color:+c.close>=+c.open?'rgba(43,194,149,0.45)':'rgba(255,71,71,0.45)'});
    var idx=-1;for(var j=0;j<allCandles.length;j++){if(allCandles[j].time===c.time){idx=j;break;}}
    if(idx>=0) allCandles[idx]=c; else allCandles.push(c);
  }
  updateIndicators(allCandles);
}
function changeInterval(btn){
  document.querySelectorAll('.iv-btn').forEach(function(b){b.classList.remove('active');});
  btn.classList.add('active');
  FlutterBridge.postMessage(btn.getAttribute('data-iv'));
}
function toggleInd(btn){
  var ind=btn.getAttribute('data-ind');
  activeInds[ind]=!activeInds[ind];
  btn.classList.toggle('active',activeInds[ind]);
  applyIndVisibility();
}
function applyIndVisibility(){
  if(volumeSeries) volumeSeries.applyOptions({visible:activeInds.VOL});
  if(ma7){ma7.applyOptions({visible:activeInds.MA});ma25.applyOptions({visible:activeInds.MA});}
  if(ema9) ema9.applyOptions({visible:activeInds.EMA});
  if(bollUp){bollUp.applyOptions({visible:activeInds.BOLL});bollMid.applyOptions({visible:activeInds.BOLL});bollLow.applyOptions({visible:activeInds.BOLL});}
}
function setRng(btn,rng){
  document.querySelectorAll('.rng-btn').forEach(function(b){b.classList.remove('active');});
  btn.classList.add('active');
  if(!chart||!allCandles.length) return;
  var last=allCandles[allCandles.length-1].time;
  var map={'1d':86400,'5d':432000,'1m':2592000,'3m':7776000,'1y':31536000};
  chart.timeScale().setVisibleRange({from:last-(map[rng]||86400),to:last+3600});
}
function setScale(btn,mode){
  document.querySelectorAll('.scale-btn').forEach(function(b){b.classList.remove('active');});
  btn.classList.add('active');
  if(chart) chart.priceScale('right').applyOptions({mode:mode==='log'?1:0});
}
(function tick(){
  var d=new Date(),p=function(n){return String(n).padStart(2,'0');};
  var el=document.getElementById('utc-clock');
  if(el) el.textContent=p(d.getUTCHours())+':'+p(d.getUTCMinutes())+':'+p(d.getUTCSeconds())+' UTC';
  setTimeout(tick,1000);
})();

window.onload=function(){ initChart(); };
</script>
</body>
</html>''';

    final htmlFile = File('${dir.path}/trapix_chart.html');
    await htmlFile.writeAsString(html, flush: true);
    _htmlPath = htmlFile.path;
  }

  WebViewController _buildController() {
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0b0b0b))
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onWebResourceError: (e) {
          debugPrint('WebView error: ${e.description} url=${e.url}');
        },
      ));

    c.addJavaScriptChannel(
      'FlutterBridge',
      onMessageReceived: (msg) {
        _currentInterval = msg.message;
        _candles = [];
        _pollTimer?.cancel();
        _fetchAndUpdate(replace: true, skipHtmlLoad: true);
      },
    );

    c.addJavaScriptChannel(
      'ChartReady',
      onMessageReceived: (_) {
        debugPrint('ChartReady received!');
        _chartReady = true;
        if (_candles.isNotEmpty) _pushData(_candles, replace: true);
        if (mounted) setState(() => _isLoading = false);
        _startPolling();
      },
    );

    return c;
  }

  Future<List<dynamic>> _fetchKlines({int limit = 200}) async {
    final url = 'https://api.trapix.com/api/v1/spot/klines/${widget.symbol}'
        '?interval=$_currentInterval&limit=$limit';
    debugPrint('Fetching klines: $url');
    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      debugPrint('klines status: ${res.statusCode} body[50]: ${res.body.substring(0, res.body.length.clamp(0, 50))}');
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final data = json is Map ? (json['data'] ?? json) : json;
        if (data is List) return data;
      }
    } catch (e) {
      debugPrint('fetchKlines error: $e');
    }
    return [];
  }

  Future<void> _fetchAndUpdate(
      {bool replace = true, bool skipHtmlLoad = false}) async {
    final fresh = await _fetchKlines(limit: replace ? 200 : 10);
    if (!mounted) return;

    if (replace) {
      _candles = fresh.isEmpty ? [] : fresh;
      if (!skipHtmlLoad) {
        if (mounted) setState(() => _isLoading = true);
        _chartReady = false;
        await _controller.loadFile(_htmlPath!);
        // ChartReady channel fires from JS after initChart() completes,
        // then _pushData is called from the ChartReady handler.
      } else {
        if (_chartReady && _candles.isNotEmpty) {
          _pushData(_candles, replace: true);
          if (mounted) setState(() => _isLoading = false);
        }
        _startPolling();
      }
    } else {
      if (fresh.isEmpty || !_chartReady) return;
      final lastTime = _candles.isNotEmpty ? (_candles.last['time'] ?? 0) : 0;
      final newCandles =
          fresh.where((c) => (c['time'] ?? 0) >= lastTime).toList();
      if (newCandles.isNotEmpty) {
        for (final c in newCandles) {
          final idx = _candles.indexWhere((x) => x['time'] == c['time']);
          if (idx >= 0) _candles[idx] = c; else _candles.add(c);
        }
        _pushData(newCandles, replace: false);
      }
    }
  }

  void _pushData(List<dynamic> candles, {required bool replace}) {
    final json = jsonEncode(candles);
    final fn = replace ? 'setChartData' : 'updateChartData';
    _controller.runJavaScript('if(typeof $fn==="function")$fn($json);');
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchAndUpdate(replace: false);
    });
  }

  void _loadChart() {
    if (_htmlPath == null) return;
    setState(() => _isLoading = true);
    _fetchAndUpdate(replace: true);
  }

  Future<void> _reloadHtmlForSymbol() async {
    if (_lwcJsPath == null) return;
    await _writeHtmlFile(widget.symbol);
    _loadChart();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          WebViewWidget(
            controller: _controller,
            gestureRecognizers: {
              Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer()),
              Factory<HorizontalDragGestureRecognizer>(
                  () => HorizontalDragGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(
                  () => ScaleGestureRecognizer()),
            },
          ),
          if (_isLoading)
            Container(
              color: const Color(0xFF0b0b0b),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2BC295),
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
