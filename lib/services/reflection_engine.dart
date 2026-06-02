import 'dart:math';
import '../models/companion.dart';
import '../models/mood.dart';

/// "Catatan Asisten" lokal berbasis aturan — tanpa model AI, jalan instan di
/// semua HP. Menghasilkan satu kalimat hangat sesuai mood, isi, tag, dan
/// kepribadian karakter terpilih.
class ReflectionEngine {
  ReflectionEngine._();

  static final _rand = Random();

  static String note({
    required Mood mood,
    required String content,
    required List<String> tags,
    required Companion companion,
  }) {
    final text = content.toLowerCase();
    final tired =
        RegExp(r'lelah|capek|cape|penat|ngantuk|lk?elah').hasMatch(text);
    final topic = tags.isNotEmpty ? tags.first : null;

    final tone = switch (mood) {
      Mood.amazing || Mood.happy => _Tone.positive,
      Mood.neutral => _Tone.neutral,
      Mood.sad || Mood.angry => _Tone.tough,
    };

    final lines = _bank[companion.id]?[tone] ?? _bank['aira']![tone]!;
    var line = lines[_rand.nextInt(lines.length)];

    // Tambahkan sentuhan kontekstual bila relevan.
    if (tired && tone != _Tone.positive) {
      line = '$line ${_tiredSuffix[companion.id] ?? _tiredSuffix['aira']!}';
    } else if (topic != null) {
      line = line.replaceAll('{topic}', topic);
    }
    line = line.replaceAll('{topic}', topic ?? 'hal ini');
    return line;
  }

  static const _tiredSuffix = {
    'aira': 'Istirahat yang cukup ya 🌙',
    'naya': 'Jangan lupa istirahat, bukannya aku khawatir sih.',
    'orion': 'Tidur cukup akan memulihkan fokusmu.',
    'luna': 'Tubuhmu juga butuh dipeluk istirahat 🌙',
    'atlas': 'Pulih dulu, besok lanjut dengan tenaga penuh.',
  };

  static const _bank = <String, Map<_Tone, List<String>>>{
    'aira': {
      _Tone.positive: [
        'Senang lihat harimu cerah! Rayakan hal kecil ini ya 🌸',
        'Energi baikmu terasa dari tulisan ini. Pertahankan!',
      ],
      _Tone.neutral: [
        'Hari yang biasa pun layak dicatat. Terima kasih sudah menulis 💜',
        'Pelan-pelan saja, kamu sudah cukup hari ini.',
      ],
      _Tone.tough: [
        'Aku tahu soal {topic} terasa berat. Kamu tidak sendiri ya.',
        'Berat ya hari ini. Bangga kamu masih menuliskannya 💜',
      ],
    },
    'naya': {
      _Tone.positive: [
        'Hmph, boleh juga harimu. Jangan kebablasan senyum ya 😼',
        'Bagus deh. Bukan berarti aku ikut senang, ya.',
      ],
      _Tone.neutral: [
        'Biasa aja sih hari ini. Tapi ya, kamu nulis juga. Lumayan.',
        'Datar? Nggak apa. Nggak semua hari harus heboh.',
      ],
      _Tone.tough: [
        'Soal {topic} nyebelin ya. Sini cerita, aku dengerin kok.',
        'Berat ya. Aku... ada di sini, jangan ge-er.',
      ],
    },
    'orion': {
      _Tone.positive: [
        'Momentum bagus. Catat apa yang berhasil agar bisa diulang.',
        'Pola positif terbentuk. Pertahankan kebiasaannya.',
      ],
      _Tone.neutral: [
        'Hari stabil itu fondasi. Konsistensi mengalahkan intensitas.',
        'Tidak ada lonjakan, tidak masalah. Tetap progres.',
      ],
      _Tone.tough: [
        'Soal {topic}: coba pecah jadi satu langkah kecil untuk besok.',
        'Hari sulit memberi data. Apa satu hal yang bisa diperbaiki?',
      ],
    },
    'luna': {
      _Tone.positive: [
        'Indah sekali perasaanmu hari ini. Aku ikut tersenyum 🌸',
        'Simpan kehangatan ini, kamu pantas merasakannya.',
      ],
      _Tone.neutral: [
        'Apa pun yang kamu rasa hari ini, itu valid kok.',
        'Terima kasih sudah jujur dengan dirimu sendiri.',
      ],
      _Tone.tough: [
        'Perasaanmu soal {topic} masuk akal. Aku di sini menemani.',
        'Boleh kok merasa berat. Kamu sudah kuat hari ini.',
      ],
    },
    'atlas': {
      _Tone.positive: [
        'Kemenangan hari ini nyata. Tandai dan lanjutkan besok!',
        'Hebat! Jadikan ini batu pijakan target berikutnya 🎯',
      ],
      _Tone.neutral: [
        'Langkah kecil tetap langkah. Besok satu langkah lagi.',
        'Stabil itu bagus. Tetapkan satu target ringan untuk besok.',
      ],
      _Tone.tough: [
        'Soal {topic}: fokus ke satu aksi terkecil yang bisa kamu kontrol.',
        'Hari berat bukan kegagalan. Reset, lalu mulai dari yang mudah.',
      ],
    },
  };
}

enum _Tone { positive, neutral, tough }
