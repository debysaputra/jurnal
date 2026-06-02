import 'package:flutter/material.dart';
import '../services/ai_context.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'companion_picker_screen.dart';

class _ChatMsg {
  final String text;
  final bool fromUser;
  _ChatMsg(this.text, this.fromUser);
}

class OfflineAiScreen extends StatefulWidget {
  const OfflineAiScreen({super.key});

  @override
  State<OfflineAiScreen> createState() => _OfflineAiScreenState();
}

class _OfflineAiScreenState extends State<OfflineAiScreen> {
  final _inputCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  late Companion _companion =
      Companion.byId(StorageService.instance.selectedCompanionId);
  final _messages = <_ChatMsg>[];
  bool _generating = false;
  bool _negativeMood = false;
  bool _hasKey = GeminiService.hasKey;

  @override
  void initState() {
    super.initState();
    if (_hasKey) _loadHistory();
  }

  @override
  void dispose() {
    _persist();
    _inputCtrl.dispose();
    _keyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ---------- Persona & emosi ----------
  bool _isNegative(String t) {
    final s = t.toLowerCase();
    return RegExp(
      r'sedih|kecewa|capek|cape|lelah|marah|kesal|stres|gagal|takut|cemas|'
      r'nangis|menyerah|berat|sakit|galau|sepi|kesepian|bosan',
    ).hasMatch(s);
  }

  String _buildSystemInstruction() {
    return '${_companion.systemInstruction} '
        'Lawan bicaramu bernama ${StorageService.instance.userName}. '
        '${AiContext.build()} '
        'Awali setiap balasan dengan satu label emosi dalam kurung siku sesuai '
        'perasaanmu: [senang], [sedih], [marah], atau [netral]. '
        'Contoh: "[senang] Hai!".';
  }

  ({String text, bool negative, String? emotion}) _parseEmotion(String raw) {
    final tagRe = RegExp(
      r'\[(senang|sedih|marah|netral|happy|sad|angry|neutral)\]',
      caseSensitive: false,
    );
    final first = tagRe.firstMatch(raw);
    String? emotion;
    var negative = _negativeMood;
    if (first != null) {
      emotion = first.group(1)!.toLowerCase();
      negative = const ['sedih', 'marah', 'sad', 'angry'].contains(emotion);
    }
    var t = raw.replaceAll(tagRe, '');
    t = t.replaceAll(r'\n', '\n').replaceAll('/n', '\n');
    t = t.replaceAll(RegExp(r'[ \t]+\n'), '\n').replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return (text: t.trim(), negative: negative, emotion: emotion);
  }

  // ---------- History ----------
  void _persist() {
    final msgs = _messages
        .where((m) => m.text.trim().isNotEmpty)
        .map((m) => {'u': m.fromUser, 't': m.text})
        .toList();
    StorageService.instance.saveChatHistory(_companion.id, msgs);
  }

  void _loadHistory() {
    final saved = StorageService.instance.chatHistory(_companion.id);
    _messages
      ..clear()
      ..addAll(saved.map((m) => _ChatMsg(m['t'] as String, m['u'] as bool)));
    if (_messages.isEmpty) {
      _messages.add(_ChatMsg(
        'Hai, aku ${_companion.name} ${_companion.emoji} '
        'Ada yang ingin kamu ceritakan hari ini?',
        false,
      ));
    }
  }

  List<Map<String, String>> _historyForApi() {
    // Kecualikan 2 pesan terakhir (pesan user baru + placeholder ketik).
    final end = _messages.length - 2;
    final out = <Map<String, String>>[];
    for (var i = 0; i < end; i++) {
      final m = _messages[i];
      if (m.text.trim().isEmpty) continue;
      out.add({'role': m.fromUser ? 'user' : 'model', 't': m.text, 'text': m.text});
    }
    // Gemini mulai dari giliran user.
    while (out.isNotEmpty && out.first['role'] == 'model') {
      out.removeAt(0);
    }
    return out;
  }

  // ---------- Aksi ----------
  void _saveKey() {
    final k = _keyCtrl.text.trim();
    if (k.isEmpty) return;
    StorageService.instance.geminiApiKey = k;
    setState(() {
      _hasKey = true;
      _loadHistory();
    });
  }

  Future<void> _changeCompanion() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CompanionPickerScreen()),
    );
    final next = Companion.byId(StorageService.instance.selectedCompanionId);
    if (!mounted || next.id == _companion.id) return;
    _persist();
    setState(() {
      _companion = next;
      _negativeMood = false;
      if (_hasKey) _loadHistory();
    });
  }

  Future<void> _clearChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus percakapan?'),
        content: Text('Riwayat chat dengan ${_companion.name} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await StorageService.instance.clearChatHistory(_companion.id);
    if (!mounted) return;
    setState(() {
      _negativeMood = false;
      _loadHistory();
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _generating) return;
    _inputCtrl.clear();
    final history = _historyForApi();
    setState(() {
      _negativeMood = _isNegative(text);
      _messages.add(_ChatMsg(text, true));
      _messages.add(_ChatMsg('', false));
      _generating = true;
    });
    _persist();
    _scrollToBottom();
    try {
      final reply = await GeminiService.instance.chat(
        systemInstruction: _buildSystemInstruction(),
        history: history,
        message: text,
      );
      final parsed = _parseEmotion(reply);
      if (!mounted) return;
      setState(() {
        if (parsed.emotion != null) _negativeMood = parsed.negative;
        _messages[_messages.length - 1] = _ChatMsg(
          parsed.text.isEmpty ? 'Maaf, aku belum bisa menjawab itu.' : parsed.text,
          false,
        );
      });
    } catch (e) {
      if (mounted) {
        setState(() => _messages[_messages.length - 1] =
            _ChatMsg('Gagal terhubung ke Gemini: $e', false));
      }
    } finally {
      if (mounted) {
        setState(() => _generating = false);
        _persist();
      }
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Text('${_companion.name} ${_companion.emoji}'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'GEMINI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_rounded),
            tooltip: 'Ganti karakter',
            onPressed: _changeCompanion,
          ),
          if (_hasKey)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Hapus percakapan',
              onPressed: _clearChat,
            ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: _hasKey ? _chatView() : _needKeyView(),
        ),
      ),
    );
  }

  Widget _needKeyView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔑', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              const Text(
                'Hubungkan Gemini',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chat ini memakai AI Gemini (online). Tempel API key Gemini-mu. '
                'Key gratis dari aistudio.google.com/apikey. '
                'Catatan: isi chat dikirim ke server Google.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkSoft, height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _keyCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Tempel API key (AIza...)',
                  prefixIcon: Icon(Icons.vpn_key_rounded),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveKey,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Simpan & mulai'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatView() {
    final portrait = _companion.portraitFor(negative: _negativeMood);
    return Column(
      children: [
        if (portrait != null)
          SizedBox(
            height: 320,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Image.asset(
                    portrait,
                    key: ValueKey(portrait),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.45, 1.0],
                      colors: [Colors.transparent, AppColors.surface],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 10,
                  child: Row(
                    children: [
                      Text(
                        '${_companion.name} ${_companion.emoji}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _companion.accent.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _negativeMood ? 'mendengarkan 🫂' : 'online',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: _messages.length,
            itemBuilder: (_, i) => _bubble(_messages[i]),
          ),
        ),
        _inputBar(),
      ],
    );
  }

  Widget _bubble(_ChatMsg m) {
    final isUser = m.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: m.text.isEmpty
            ? const SizedBox(
                width: 24,
                child: Text('…',
                    style: TextStyle(fontSize: 18, color: AppColors.inkSoft)),
              )
            : Text(
                m.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.ink,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Tulis pesan untuk ${_companion.name}…',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _generating ? null : _send,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _generating ? AppColors.inkSoft : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _generating ? Icons.more_horiz_rounded : Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
