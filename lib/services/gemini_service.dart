import 'package:firebase_ai/firebase_ai.dart';
export '../models/companion.dart';

/// Klien Gemini lewat Firebase AI Logic (backend Gemini Developer API).
///
/// Tidak ada API key di dalam APK: permintaan diteruskan lewat backend
/// Firebase milik project ini. Firebase wajib sudah diinisialisasi di main().
/// Catatan: isi chat tetap dikirim ke server Google saat fitur ini dipakai.
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  /// Model cepat & pintar. Bisa diganti bila perlu.
  static const model = 'gemini-2.5-flash';
  static const modelDisplayName = 'Gemini 2.5 Flash';

  /// Tidak perlu key lagi — selalu siap setelah Firebase diinisialisasi.
  static bool get hasKey => true;

  /// Kirim percakapan ke Gemini, kembalikan teks balasan.
  /// [history] = daftar {'role':'user'|'model','text':...} (tanpa pesan terbaru).
  Future<String> chat({
    required String systemInstruction,
    required List<Map<String, String>> history,
    required String message,
  }) async {
    final genModel = FirebaseAI.googleAI().generativeModel(
      model: model,
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.9,
        maxOutputTokens: 400,
      ),
    );

    final session = genModel.startChat(
      history: [
        for (final h in history)
          h['role'] == 'user'
              ? Content.text(h['text'] ?? '')
              : Content.model([TextPart(h['text'] ?? '')]),
      ],
    );

    final response = await session.sendMessage(Content.text(message));
    final text = response.text?.trim() ?? '';
    if (text.isEmpty) {
      throw Exception('Tidak ada balasan dari Gemini.');
    }
    return text;
  }
}
