import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/language_util.dart';

const _base = 'https://api.trapix.com/api/knowledgebase';
const _green = Color(0xFFCCFF00);
const _bg = Color(0xFF111111);
const _card = Color(0xFF15181D);
const _dim = Color(0xFF6B7280);

Map<String, String> _headers() {
  final token = GetStorage().read(PreferenceKey.accessToken) ?? '';
  final type = GetStorage().read(PreferenceKey.accessType) ?? 'Bearer';
  return {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    APIKeyConstants.userApiSecret: dotenv.env[EnvKeyValue.kApiSecret] ?? '',
    APIKeyConstants.lang: LanguageUtil.getCurrentKey(),
    if (token.toString().isNotEmpty) APIKeyConstants.authorization: '$type $token',
  };
}

Map<String, String> _headersNoJson() {
  final h = _headers();
  h.remove('Content-Type');
  return h;
}

// ─── Models ────────────────────────────────────────────────────────────────

class SupportTicket {
  final int id;
  final String uniqueCode;
  final String title;
  final String status;
  final String createdAt;
  final String? lastMessage;

  SupportTicket({
    required this.id,
    required this.uniqueCode,
    required this.title,
    required this.status,
    required this.createdAt,
    this.lastMessage,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> j) => SupportTicket(
        id: j['id'] ?? 0,
        uniqueCode: j['unique_code'] ?? '',
        title: j['title'] ?? '',
        status: (j['status'] ?? '').toString(),
        createdAt: j['created_at'] ?? '',
        lastMessage: j['last_reply']?['message'],
      );
}

class TicketMessage {
  final int id;
  final String message;
  final bool isMine;
  final String? photo;
  final String createdAt;
  final List<String> attachments;

  TicketMessage({
    required this.id,
    required this.message,
    required this.isMine,
    this.photo,
    required this.createdAt,
    required this.attachments,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> j, int myId) {
    final userId = j['user_id'] ?? j['user']?['id'] ?? 0;
    final atts = <String>[];
    if (j['conversation_attachment'] is List) {
      for (final a in j['conversation_attachment']) {
        if (a['file_link'] != null) atts.add(a['file_link']);
      }
    }
    return TicketMessage(
      id: j['id'] ?? 0,
      message: j['message'] ?? '',
      isMine: userId == myId,
      photo: j['user']?['photo'],
      createdAt: j['created_at'] ?? '',
      attachments: atts,
    );
  }
}

class SupportProject {
  final int id;
  final String name;
  SupportProject({required this.id, required this.name});
  factory SupportProject.fromJson(Map<String, dynamic> j) =>
      SupportProject(id: j['id'] ?? 0, name: j['project_name'] ?? j['name'] ?? '');
}

class SupportCategory {
  final int id;
  final String name;
  SupportCategory({required this.id, required this.name});
  factory SupportCategory.fromJson(Map<String, dynamic> j) =>
      SupportCategory(id: j['id'] ?? 0, name: j['name'] ?? '');
}

// ─── Main Support Screen ────────────────────────────────────────────────────

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<SupportTicket> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$_base/support-ticket-list?limit=20&page=1'),
        headers: _headers(),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body['data']?['ticket_list']?['data'] as List? ?? [];
        setState(() => _tickets = list.map((e) => SupportTicket.fromJson(e)).toList());
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case '1':
      case 'open':
        return Colors.green;
      case '2':
      case 'pending':
        return Colors.orange;
      case '0':
      case 'closed':
        return Colors.red;
      default:
        return _dim;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case '1':
        return 'Open';
      case '2':
        return 'Pending';
      case '0':
        return 'Closed';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Support', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTicketScreen()));
              _load();
            },
            icon: const Icon(Icons.add, color: _green, size: 18),
            label: const Text('New Ticket', style: TextStyle(color: _green, fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _tickets.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.headset_off, color: _dim, size: 48),
                    const SizedBox(height: 12),
                    const Text('No support tickets yet', style: TextStyle(color: _dim, fontSize: 15)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.black),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTicketScreen()));
                        _load();
                      },
                      child: const Text('Create Ticket'),
                    ),
                  ]),
                )
              : RefreshIndicator(
                  color: _green,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _tickets.length,
                    itemBuilder: (_, i) {
                      final t = _tickets[i];
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => TicketChatScreen(ticket: t),
                          ));
                          _load();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF222222)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.confirmation_number_outlined, color: _green, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(t.lastMessage ?? 'No messages yet',
                                  style: const TextStyle(color: _dim, fontSize: 12),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ])),
                            const SizedBox(width: 10),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _statusColor(t.status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _statusColor(t.status).withOpacity(0.4)),
                                ),
                                child: Text(_statusLabel(t.status),
                                    style: TextStyle(color: _statusColor(t.status), fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(height: 4),
                              const Icon(Icons.arrow_forward_ios, color: _dim, size: 12),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ─── Ticket Chat Screen ─────────────────────────────────────────────────────

class TicketChatScreen extends StatefulWidget {
  final SupportTicket ticket;
  const TicketChatScreen({super.key, required this.ticket});

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  List<TicketMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  int _myId = 0;
  File? _attachment;

  @override
  void initState() {
    super.initState();
    _myId = GetStorage().read('user_id') ?? 0;
    _load();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$_base/support-ticket-conversation-details?unique_code=${widget.ticket.uniqueCode}'),
        headers: _headers(),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body['data']?['conversation_list'] as List? ?? [];
        setState(() => _messages = list.map((e) => TicketMessage.fromJson(e, _myId)).toList());
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  Future<void> _send() async {
    final msg = _textCtrl.text.trim();
    if (msg.isEmpty && _attachment == null) return;
    setState(() => _sending = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_base/support-ticket-conversation-send'),
      );
      request.headers.addAll(_headersNoJson());
      request.fields['message'] = msg;
      request.fields['ticket_unique_code'] = widget.ticket.uniqueCode;
      if (_attachment != null) {
        request.files.add(await http.MultipartFile.fromPath('files_name[1]', _attachment!.path));
      }
      final streamed = await request.send();
      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        _textCtrl.clear();
        setState(() => _attachment = null);
        await _load();
      }
    } catch (_) {}
    setState(() => _sending = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _attachment = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.ticket.title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('Ticket #${widget.ticket.id}', style: const TextStyle(color: _dim, fontSize: 11)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : Column(children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _MessageBubble(msg: _messages[i]),
                ),
              ),
              if (_attachment != null)
                Container(
                  color: _card,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(_attachment!, width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Image attached', style: TextStyle(color: Colors.white, fontSize: 13))),
                    IconButton(
                      icon: const Icon(Icons.close, color: _dim, size: 18),
                      onPressed: () => setState(() => _attachment = null),
                    ),
                  ]),
                ),
              Container(
                color: _card,
                padding: EdgeInsets.only(
                  left: 16, right: 16,
                  top: 10,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                ),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: _dim, size: 22),
                    onPressed: _pickImage,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: _dim, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sending ? null : _send,
                    child: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : const Icon(Icons.send, color: Colors.black, size: 18),
                    ),
                  ),
                ]),
              ),
            ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF222222),
              backgroundImage: msg.photo != null ? NetworkImage(msg.photo!) : null,
              child: msg.photo == null ? const Icon(Icons.support_agent, color: _green, size: 16) : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (msg.message.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isMine ? _green : _card,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isMine ? 16 : 4),
                        bottomRight: Radius.circular(msg.isMine ? 4 : 16),
                      ),
                    ),
                    child: Text(msg.message,
                        style: TextStyle(
                          color: msg.isMine ? Colors.black : Colors.white,
                          fontSize: 14,
                        )),
                  ),
                for (final att in msg.attachments)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(att, width: 180, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    ),
                  ),
              ],
            ),
          ),
          if (msg.isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Create Ticket Screen ───────────────────────────────────────────────────

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  List<SupportProject> _projects = [];
  List<SupportCategory> _categories = [];
  SupportProject? _selectedProject;
  SupportCategory? _selectedCategory;
  File? _file;
  bool _loading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$_base/support-project-list'),
        headers: _headers(),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final pList = (body['data']?['project_list'] as List? ?? [])
            .map((e) => SupportProject.fromJson(e))
            .toList();
        final cList = (body['data']?['category'] as List? ?? [])
            .map((e) => SupportCategory.fromJson(e))
            .toList();
        setState(() {
          _projects = pList;
          _categories = cList;
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Please enter a title');
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _snack('Please enter a description');
      return;
    }
    setState(() => _submitting = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_base/support-ticket-store'),
      );
      request.headers.addAll(_headersNoJson());
      request.fields['title'] = _titleCtrl.text.trim();
      request.fields['description'] = _descCtrl.text.trim();
      if (_selectedProject != null) request.fields['project_id'] = _selectedProject!.id.toString();
      if (_selectedCategory != null) request.fields['category_id'] = _selectedCategory!.id.toString();
      if (_file != null) request.files.add(await http.MultipartFile.fromPath('file[1]', _file!.path));
      final streamed = await request.send();
      final body = jsonDecode(await streamed.stream.bytesToString());
      if (body['success'] == true) {
        if (mounted) {
          _snack('Ticket created successfully!');
          Navigator.pop(context);
        }
      } else {
        _snack(body['message'] ?? 'Failed to create ticket');
      }
    } catch (_) {
      _snack('Something went wrong');
    }
    setState(() => _submitting = false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF1A1A1A)),
    );
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _file = File(picked.path));
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Ticket', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Category
                if (_categories.isNotEmpty) ...[
                  _label('Category'),
                  _Dropdown<SupportCategory>(
                    hint: 'Select Category',
                    value: _selectedCategory,
                    items: _categories,
                    label: (c) => c.name,
                    onChanged: (c) => setState(() => _selectedCategory = c),
                  ),
                  const SizedBox(height: 16),
                ],

                // Project
                if (_projects.isNotEmpty) ...[
                  _label('Project'),
                  _Dropdown<SupportProject>(
                    hint: 'Select Project',
                    value: _selectedProject,
                    items: _projects,
                    label: (p) => p.name,
                    onChanged: (p) => setState(() => _selectedProject = p),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                _label('Title'),
                _Input(controller: _titleCtrl, hint: 'Ticket title'),
                const SizedBox(height: 16),

                // Description
                _label('Description'),
                _Input(controller: _descCtrl, hint: 'Describe your issue...', maxLines: 5),
                const SizedBox(height: 16),

                // Attachment
                _label('Attachment (optional)'),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(
                        _file != null ? Icons.check_circle : Icons.upload_file,
                        color: _file != null ? _green : _dim,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _file != null ? 'File selected' : 'Tap to upload image',
                        style: TextStyle(color: _file != null ? _green : _dim, fontSize: 14),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text('Submit Ticket', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

class _Dropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) label;
  final void Function(T?) onChanged;

  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: DropdownButton<T>(
        isExpanded: true,
        value: value,
        hint: Text(hint, style: const TextStyle(color: _dim, fontSize: 14)),
        dropdownColor: const Color(0xFF1A1A1A),
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, color: _dim),
        items: items.map((item) => DropdownMenuItem<T>(
              value: item,
              child: Text(label(item), style: const TextStyle(color: Colors.white, fontSize: 14)),
            )).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _Input({required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _dim, fontSize: 14),
        filled: true,
        fillColor: _card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green),
        ),
      ),
    );
  }
}
