import 'package:flutter/material.dart';
import '../services/ondevice_ai_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'companion_picker_screen.dart';

enum _Phase { checking, needDownload, downloading, loading, ready, error }

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
  final _ai = OndeviceAiService.instance;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  _Phase _phase = _Phase.checking;
  String _error = '';
  int _progress = 0;
  late Companion _companion =
      Companion.byId(StorageService.instance.selectedCompanionId);
  final _messages = <_ChatMsg>[];
  bool _generating = false;
  bool _negativeMood = false;

  bool _isNegative(String t) {
    final s = t.toLowerCase();
    return RegExp(
      r'sedih|kecewa|capek|cape|lelah|marah|kesal|stres|gagal|takut|cemas|'
      r'nangis|menyerah|berat|sakit|galau|sepi|kesepian|bosan',
    ).hasMatch(s);
  }

  /// Pisahkan label emosi `[senang]/[sedih]/...` di awal balasan AI dari teksnya.
  /// `emotion` null bila label belum lengkap/ada; `text` sudah tanpa label.
  ({String text, bool negative, String? emotion}) _parseEmotion(String raw) {
    final m = RegExp(
      r'^\s*\[(senang|sedih|marah|netral|happy|sad|angry|neutral)\]\s*',
      caseSensitive: false,
    ).firstMatch(raw);
    if (m != null) {
      final e = m.group(1)!.toLowerCase();
      final neg = e == 'sedih' || e == 'marah' || e == 'sad' || e == 'angry';
      return (text: raw.substring(m.end), negative: neg, emotion: e);
    }
    // Label mungkin masih separuh terkirim ("[sen") → sembunyikan dulu.
    final partial = RegExp(r'^\s*\[[^\]]*$').hasMatch(raw);
    return (text: partial ? '' : raw, negative: _negativeMood, emotion: null);
  }

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _changeCompanion() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CompanionPickerScreen()),
    );
    final next = Companion.byId(StorageService.instance.selectedCompanionId);
    if (!mounted || next.id == _companion.id) return;
    setState(() {
      _companion = next;
      _messages.clear();
    });
    if (_ai.isLoaded) {
      await _ai.unload();
      await _load();
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _ai.unload();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _phase = _Phase.checking);
    try {
      final installed = await _ai.isInstalled();
      if (!mounted) return;
      if (installed) {
        await _load();
      } else {
        // Unduh manual: tampilkan tombol, biar user yang memulai.
        setState(() => _phase = _Phase.needDownload);
      }
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _download() async {
    setState(() {
      _phase = _Phase.downloading;
      _progress = 0;
    });
    try {
      await _ai.download((p) {
        if (mounted) setState(() => _progress = p);
      });
      if (!mounted) return;
      await _load();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _load() async {
    setState(() => _phase = _Phase.loading);
    try {
      final si = '${_companion.systemInstruction} '
          'Lawan bicaramu bernama ${StorageService.instance.userName}.';
      await _ai.load(systemInstruction: si);
      if (!mounted) return;
      setState(() {
        _phase = _Phase.ready;
        if (_messages.isEmpty) {
          _messages.add(_ChatMsg(
            'Hai, aku ${_companion.name} ${_companion.emoji} '
            'Aku jalan sepenuhnya di HP-mu, jadi obrolan kita privat. '
            'Ada yang ingin kamu ceritakan?',
            false,
          ));
        }
      });
    } catch (e) {
      _fail(e);
    }
  }

  void _fail(Object e) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.error;
      _error = e.toString();
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _generating) return;
    _inputCtrl.clear();
    setState(() {
      _negativeMood = _isNegative(text);
      _messages.add(_ChatMsg(text, true));
      _messages.add(_ChatMsg('', false));
      _generating = true;
    });
    _scrollToBottom();
    try {
      final buffer = StringBuffer();
      await for (final token
          in _ai.sendMessage(text, reminder: _companion.chatReminder)) {
        buffer.write(token);
        if (!mounted) return;
        final parsed = _parseEmotion(buffer.toString());
        setState(() {
          // Ekspresi gambar mengikuti emosi balasan AI.
          if (parsed.emotion != null) _negativeMood = parsed.negative;
          _messages[_messages.length - 1] = _ChatMsg(parsed.text, false);
        });
        _scrollToBottom();
      }
      final finalText = _parseEmotion(buffer.toString()).text.trim();
      if (finalText.isEmpty && mounted) {
        setState(() => _messages[_messages.length - 1] =
            _ChatMsg('(maaf, aku belum punya jawaban)', false));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages[_messages.length - 1] =
            _ChatMsg('Terjadi kesalahan: $e', false));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
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
                'OFFLINE',
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
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: switch (_phase) {
            _Phase.checking => _centered(
                const CircularProgressIndicator(),
                'Memeriksa model…',
              ),
            _Phase.needDownload => _downloadPrompt(),
            _Phase.downloading => _centered(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: _progress > 0 ? _progress / 100 : null,
                        strokeWidth: 6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_progress%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                'Mengunduh ${OndeviceAiService.modelDisplayName} '
                '(${OndeviceAiService.modelSizeLabel})…\n'
                'Disarankan pakai WiFi. Biarkan aplikasi terbuka.',
              ),
            _Phase.loading => _centered(
                const CircularProgressIndicator(),
                'Memuat AI ke memori…',
              ),
            _Phase.error => _errorView(),
            _Phase.ready => _chatView(),
          },
        ),
      ),
    );
  }

  Widget _centered(Widget top, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            top,
            const SizedBox(height: 20),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _downloadPrompt() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤖', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'Mode AI Offline',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chat dengan AI yang berjalan sepenuhnya di HP-mu — tanpa '
                'internet setelah model diunduh, dan jurnalmu tetap privat.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkSoft, height: 1.4),
              ),
              const SizedBox(height: 16),
              _infoRow(Icons.smart_toy_rounded,
                  'Model: ${OndeviceAiService.modelDisplayName}'),
              _infoRow(Icons.download_rounded,
                  'Sekali unduh ${OndeviceAiService.modelSizeLabel}'),
              _infoRow(Icons.memory_rounded,
                  'Disarankan HP dengan RAM 4 GB ke atas'),
              _infoRow(Icons.wifi_off_rounded,
                  'Setelah terunduh, bisa dipakai offline'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _download,
                  icon: const Icon(Icons.download_rounded),
                  label: Text('Unduh model (${OndeviceAiService.modelSizeLabel})'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.inkSoft),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          tint: AppColors.pink,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😕', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              const Text(
                'Gagal menyiapkan AI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 8),
              const Text(
                'Model: ${OndeviceAiService.modelDisplayName} '
                '(${OndeviceAiService.modelSizeLabel}). '
                'Pastikan koneksi internet stabil & ruang penyimpanan cukup, '
                'lalu coba lagi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _check,
                child: const Text('Coba lagi'),
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
            height: 210,
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
                // Fade ke latar di bawah agar menyatu dengan chat.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.45, 1.0],
                      colors: [
                        Colors.transparent,
                        AppColors.surface,
                      ],
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
          color: isUser
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.08),
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
