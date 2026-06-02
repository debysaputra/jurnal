import 'package:flutter_gemma/flutter_gemma.dart';
export '../models/companion.dart';

/// Mesin AI on-device memakai flutter_gemma (MediaPipe LLM Inference).
///
/// Model **diunduh** dari HuggingFace (non-gated, tanpa token) langsung ke
/// penyimpanan app — TIDAK di-bundle, agar APK kecil & menghindari proses
/// salin aset besar dari dalam APK yang rawan macet.
///
/// Model: Qwen2.5 0.5B Instruct (Apache-2.0) — multibahasa, layak untuk
/// asisten personal, ~520 MB.
class OndeviceAiService {
  OndeviceAiService._();
  static final OndeviceAiService instance = OndeviceAiService._();

  static const modelUrl =
      'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task';
  static const modelFilename =
      'Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task';
  static const modelDisplayName = 'Qwen2.5 0.5B Instruct';
  static const modelSizeLabel = '± 520 MB';

  InferenceModel? _model;
  InferenceChat? _chat;

  bool get isLoaded => _chat != null;

  /// Apakah model sudah terunduh & terdaftar di perangkat.
  Future<bool> isInstalled() => FlutterGemma.isModelInstalled(modelFilename);

  /// Unduh model dari jaringan ke penyimpanan app. `onProgress` 0–100.
  Future<void> download(void Function(int progress) onProgress) async {
    await FlutterGemma.installModel(modelType: ModelType.qwen)
        .fromNetwork(modelUrl)
        .withProgress(onProgress)
        .install();
  }

  /// Muat model ke memori dan siapkan sesi chat dengan persona terpilih.
  /// install() idempotent — unduh dilewati bila model sudah ada.
  Future<void> load({required String systemInstruction}) async {
    await FlutterGemma.installModel(modelType: ModelType.qwen)
        .fromNetwork(modelUrl)
        .install();

    // maxTokens kecil = cache lebih kecil = lebih ringan di RAM (HP terbatas).
    _model = await FlutterGemma.getActiveModel(
      maxTokens: 512,
      preferredBackend: PreferredBackend.cpu,
    );
    _chat = await _model!.createChat(
      temperature: 0.8,
      topK: 40,
      topP: 0.95,
      tokenBuffer: 128,
      modelType: ModelType.qwen,
      systemInstruction: systemInstruction,
    );
  }

  /// Kirim pesan, terima jawaban sebagai stream token (untuk efek mengetik).
  /// [reminder] = pengingat persona singkat yang diselipkan ke model
  /// (tidak ditampilkan ke user) agar karakter konsisten tiap giliran.
  Stream<String> sendMessage(String text, {String? reminder}) async* {
    final chat = _chat;
    if (chat == null) {
      throw StateError('Model belum dimuat. Panggil load() dulu.');
    }
    final payload =
        (reminder == null || reminder.isEmpty) ? text : '$reminder\n$text';
    await chat.addQueryChunk(Message.text(text: payload, isUser: true));
    await for (final response in chat.generateChatResponseAsync()) {
      if (response is TextResponse) {
        yield response.token;
      }
    }
  }

  /// Lepas model dari memori (mis. saat keluar dari layar chat).
  Future<void> unload() async {
    await _chat?.close();
    await _model?.close();
    _chat = null;
    _model = null;
  }

  /// Hapus file model dari perangkat.
  Future<void> delete() async {
    await unload();
    await FlutterGemma.uninstallModel(modelFilename);
  }
}
