import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

const _chatApi = 'https://api.trapix.com/api/live-chat';
const _green = Color(0xFFCCFF00);
const _bg = Color(0xFF000000);
const _bubble = Color(0xFF111111);

// ─── Model ─────────────────────────────────────────────────────────────────

class _Msg {
  final int id;
  final String sender; // 'user' | 'ai' | 'admin'
  final String message;

  _Msg({required this.id, required this.sender, required this.message});

  factory _Msg.fromJson(Map<String, dynamic> j) => _Msg(
        id: j['id'] ?? 0,
        sender: j['sender'] ?? 'ai',
        message: j['message'] ?? '',
      );
}

// ─── Session helpers ────────────────────────────────────────────────────────

String _getOrCreateSession() {
  final box = GetStorage();
  String? s = box.read('trapix_chat_session');
  if (s == null || s.isEmpty) {
    s = DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
        '_${UniqueKey().toString().replaceAll('[#', '').replaceAll(']', '')}';
    box.write('trapix_chat_session', s);
  }
  return s;
}

String _newSession() {
  final s = DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
      '_${DateTime.now().microsecond}';
  GetStorage().write('trapix_chat_session', s);
  return s;
}

Map<String, dynamic> _userInfo() {
  final box = GetStorage();
  return {
    'user_id': box.read('user_id'),
    'user_name': box.read('name') ?? box.read('username') ?? 'Guest',
    'user_email': box.read('email'),
  };
}

// ─── Live Chat Screen ───────────────────────────────────────────────────────

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  late String _sessionId;
  final List<_Msg> _messages = [];
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _started = false;
  bool _closing = false;
  bool _userSentMsg = false;
  bool _showEndConfirm = false;
  String _chatStatus = 'active';
  int _lastId = 0;
  Timer? _pollTimer;

  static const _quickReplies = [
    '📋 List your token on Trapix',
    'How to deposit?',
    'Withdrawal help',
    'KYC verification',
    'Trading fees',
    'Talk to human',
  ];

  @override
  void initState() {
    super.initState();
    _sessionId = _getOrCreateSession();
    _startChat();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startChat() async {
    try {
      final body = {'session_id': _sessionId, ..._userInfo()};
      final res = await http.post(
        Uri.parse('$_chatApi/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        if (d['status'] == true) {
          final msgs = (d['messages'] as List? ?? []).map((e) => _Msg.fromJson(e)).toList();
          final maxId = msgs.isNotEmpty ? msgs.map((m) => m.id).reduce((a, b) => a > b ? a : b) : 0;
          if (mounted) {
            setState(() {
              _messages.addAll(msgs);
              _chatStatus = d['chat']?['status'] ?? 'active';
              _lastId = maxId;
              _started = true;
            });
          }
          _scrollBottom();
          _startPolling();
        }
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _closing) return;
      try {
        final res = await http.get(
          Uri.parse('$_chatApi/poll?session_id=$_sessionId&since=$_lastId'),
        );
        if (res.statusCode == 200) {
          final d = jsonDecode(res.body);
          if (d['chat_status'] == 'closed') {
            _pollTimer?.cancel();
            if (mounted) {
              setState(() {
                _messages.add(_Msg(
                  id: DateTime.now().millisecondsSinceEpoch,
                  sender: 'ai',
                  message: 'This chat has been closed by our support team. Thank you for contacting Trapix! 👋',
                ));
                _closing = true;
              });
              _scrollBottom();
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) Navigator.pop(context);
              });
            }
            return;
          }
          final newMsgs = (d['messages'] as List? ?? []).map((e) => _Msg.fromJson(e)).toList();
          if (newMsgs.isNotEmpty && mounted) {
            final existingIds = _messages.where((m) => m.id > 0).map((m) => m.id).toSet();
            final fresh = newMsgs.where((m) => !existingIds.contains(m.id)).toList();
            if (fresh.isNotEmpty) {
              setState(() {
                _messages.addAll(fresh);
                _lastId = newMsgs.map((m) => m.id).reduce((a, b) => a > b ? a : b);
              });
              _scrollBottom();
            }
          }
          if (mounted) setState(() => _chatStatus = d['chat_status'] ?? _chatStatus);
        }
      } catch (_) {}
    });
  }

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _sending || _closing) return;
    setState(() {
      _sending = true;
      _userSentMsg = true;
      _messages.add(_Msg(id: -(DateTime.now().millisecondsSinceEpoch), sender: 'user', message: msg));
    });
    _scrollBottom();
    try {
      final res = await http.post(
        Uri.parse('$_chatApi/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_id': _sessionId, 'message': msg}),
      );
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        if (d['ai_reply'] != null && mounted) {
          setState(() {
            _messages.add(_Msg(
              id: -(DateTime.now().millisecondsSinceEpoch + 1),
              sender: 'ai',
              message: d['ai_reply'],
            ));
          });
          _scrollBottom();
        }
        if (d['chat_status'] == 'closed' && mounted) {
          _pollTimer?.cancel();
          setState(() => _closing = true);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.pop(context);
          });
        } else if (mounted) {
          setState(() => _chatStatus = d['chat_status'] ?? _chatStatus);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _endChat() async {
    _pollTimer?.cancel();
    setState(() {
      _closing = true;
      _showEndConfirm = false;
      _messages.add(_Msg(
        id: DateTime.now().millisecondsSinceEpoch,
        sender: 'ai',
        message: "Alright, we've closed the chat. Have a good day! 👋 Feel free to reach out anytime.",
      ));
    });
    _scrollBottom();
    try {
      await http.post(
        Uri.parse('$_chatApi/clear'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_id': _sessionId}),
      );
    } catch (_) {}
    _newSession();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) Navigator.pop(context);
    });
  }

  String get _statusLabel {
    switch (_chatStatus) {
      case 'assigned': return 'Agent Online';
      case 'human_requested': return 'Connecting to agent...';
      case 'closed': return 'Chat Closed';
      default: return 'AI Assistant Online';
    }
  }

  Color get _statusColor {
    switch (_chatStatus) {
      case 'assigned': return const Color(0xFF22C55E);
      case 'closed': return const Color(0xFFEF4444);
      default: return _green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF111111),
            child: Image.network(
              'https://trapix.com/icon/512x512 logo (1).png',
              width: 32, height: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.headset_mic, color: _green, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Trapix Support', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            Row(children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _statusColor.withOpacity(0.7), blurRadius: 6)]),
              ),
              const SizedBox(width: 5),
              Text(_statusLabel, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
            ]),
          ]),
        ]),
        actions: [
          if (!_closing)
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFFFF6666), size: 20),
              onPressed: () => setState(() => _showEndConfirm = true),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(children: [
        // End chat confirm bar
        if (_showEndConfirm)
          Container(
            color: const Color(0xFF111111),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const Expanded(child: Text('End this chat session?', style: TextStyle(color: Color(0xFFDDDDDD), fontSize: 13))),
              TextButton(
                onPressed: _endChat,
                style: TextButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
                child: const Text('Yes, End', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _showEndConfirm = false),
                style: TextButton.styleFrom(backgroundColor: const Color(0xFF2A2A2A), foregroundColor: const Color(0xFFAAAAAA), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ),

        // Status banners
        if (_chatStatus == 'human_requested')
          Container(
            color: const Color(0xFF111111),
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: const Center(child: Text('⏳ Connecting you to a live agent...', style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600))),
          ),
        if (_chatStatus == 'assigned')
          Container(
            color: const Color(0xFF001A08),
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: const Center(child: Text('✓ You are now chatting with a support agent', style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.w600))),
          ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _messages.length + (_sending ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _messages.length) return _TypingIndicator();
              return _BubbleWidget(msg: _messages[i]);
            },
          ),
        ),

        // Quick replies — hide when keyboard open
        if (!_userSentMsg && !_closing && _started && MediaQuery.of(context).viewInsets.bottom == 0)
          Container(
            color: _bg,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(spacing: 6, runSpacing: 6, children: _quickReplies.map((q) {
              return GestureDetector(
                onTap: () => _send(q),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _bg,
                    border: Border.all(color: _green),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(q, style: const TextStyle(color: _green, fontSize: 12)),
                ),
              );
            }).toList()),
          ),

        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: const BoxDecoration(
            color: _bg,
            border: Border(top: BorderSide(color: Color(0xFF1A1A1A))),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _textCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                enabled: !_closing,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: _closing ? 'Chat ended...' : 'Type your message...',
                  hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFF111111),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _green),
                  ),
                ),
                onSubmitted: (v) { _send(v); _textCtrl.clear(); },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _closing ? null : () { _send(_textCtrl.text); _textCtrl.clear(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _textCtrl.text.trim().isNotEmpty && !_closing ? _green : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.send,
                    color: _textCtrl.text.trim().isNotEmpty && !_closing ? Colors.black : const Color(0xFF555555),
                    size: 18,
                  ),
                ),
              ),
            ),
          ]),
        ),

        // Footer - hide when keyboard open to avoid overflow
        if (MediaQuery.of(context).viewInsets.bottom == 0)
          Container(
            color: _bg,
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: const Center(
              child: Text.rich(TextSpan(
                style: TextStyle(color: Color(0xFF555555), fontSize: 10),
                children: [
                  TextSpan(text: 'Powered by '),
                  TextSpan(text: 'Trapix AI', style: TextStyle(color: _green)),
                  TextSpan(text: ' · Secure & Encrypted'),
                ],
              )),
            ),
          ),
          ]),
        ),
      ),
    );
  }
}

// ─── Markdown parser (bold + bullet) ────────────────────────────────────────

List<InlineSpan> _parseMarkdown(String text, Color textColor) {
  final spans = <InlineSpan>[];
  final lines = text.split('\n');
  for (int li = 0; li < lines.length; li++) {
    final line = lines[li];
    if (li > 0) spans.add(const TextSpan(text: '\n'));
    // Parse inline **bold**
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int last = 0;
    for (final m in regex.allMatches(line)) {
      if (m.start > last) {
        spans.add(TextSpan(text: line.substring(last, m.start), style: TextStyle(color: textColor)));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ));
      last = m.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last), style: TextStyle(color: textColor)));
    }
  }
  return spans;
}

// ─── Bubble widget ──────────────────────────────────────────────────────────

class _BubbleWidget extends StatelessWidget {
  final _Msg msg;
  const _BubbleWidget({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.sender == 'user';
    final isAdmin = msg.sender == 'admin';
    final textColor = isUser ? Colors.black : const Color(0xFFDDDDDD);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            isUser ? 'You' : (isAdmin ? '👤 Support Agent' : '🤖 Trapix AI'),
            style: const TextStyle(color: Color(0xFF555555), fontSize: 10),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                  padding: EdgeInsets.only(
            left: 14, right: 14, top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 10,
          ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(colors: [Color(0xFFCCFF00), Color(0xFFA8E600)])
                        : null,
                    color: isUser ? null : _bubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isUser ? 14 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 14),
                    ),
                    border: isUser ? null : Border.all(color: const Color(0xFF222222)),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13.5, height: 1.55, color: textColor,
                          fontWeight: isUser ? FontWeight.w600 : FontWeight.w400),
                      children: _parseMarkdown(msg.message, textColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Typing indicator ───────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _bubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14), topRight: Radius.circular(14),
              bottomRight: Radius.circular(14), bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: const Color(0xFF222222)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final t = (_ctrl.value - i * 0.15).clamp(0.0, 1.0);
                final bounce = (t < 0.5 ? t * 2 : (1 - t) * 2);
                return Transform.translate(
                  offset: Offset(0, -4 * bounce),
                  child: Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                  ),
                );
              },
            );
          })),
        ),
      ]),
    );
  }
}
