import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
export '../models/companion.dart';

/// Klien Gemini (Google Generative Language API).
///
/// Memakai API key milik user yang disimpan lokal (StorageService.geminiApiKey).
/// Catatan: isi chat dikirim ke server Google saat fitur ini dipakai.
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  /// Model cepat & pintar. Bisa diganti bila perlu.
  static const model = 'gemini-2.5-flash';
  static const modelDisplayName = 'Gemini 2.5 Flash';

  /// Key bawaan dari .env (atau --dart-define saat build sebagai cadangan).
  static const _defineKey = String.fromEnvironment('GEMINI_API_KEY');
  static String get _embeddedKey {
    try {
      final fromEnv = dotenv.maybeGet('GEMINI_API_KEY') ?? '';
      if (fromEnv.isNotEmpty) return fromEnv;
    } catch (_) {}
    return _defineKey;
  }

  /// Pakai key yang diisi user; bila kosong, pakai key bawaan (.env).
  static String get _key {
    final stored = StorageService.instance.geminiApiKey;
    return stored.isNotEmpty ? stored : _embeddedKey;
  }

  static bool get hasKey => _key.isNotEmpty;

  /// Kirim percakapan ke Gemini, kembalikan teks balasan.
  /// [history] = daftar {'role':'user'|'model','text':...} (tanpa pesan terbaru).
  Future<String> chat({
    required String systemInstruction,
    required List<Map<String, String>> history,
    required String message,
  }) async {
    if (!hasKey) {
      throw Exception('API key Gemini belum diisi.');
    }
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_key',
    );
    final contents = <Map<String, dynamic>>[
      for (final h in history)
        {
          'role': h['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': h['text'] ?? ''}
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      },
    ];
    final body = {
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction}
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.9,
        'maxOutputTokens': 400,
      },
    };

    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      String msg = 'HTTP ${resp.statusCode}';
      try {
        final err = jsonDecode(resp.body);
        msg = err['error']?['message']?.toString() ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      // Bisa diblokir filter keamanan.
      final reason =
          data['promptFeedback']?['blockReason']?.toString();
      throw Exception(reason != null
          ? 'Balasan diblokir ($reason).'
          : 'Tidak ada balasan dari Gemini.');
    }
    final parts =
        candidates[0]?['content']?['parts'] as List?;
    final text = parts
        ?.map((p) => (p as Map)['text']?.toString() ?? '')
        .join()
        .trim();
    return text ?? '';
  }
}
