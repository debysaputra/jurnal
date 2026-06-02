# Rancangan AI Companion — MyJurnal (LOKAL, TANPA SERVER)

Status: **Desain** (belum implementasi)
Tanggal: 2026-06-02
Batasan utama: **Semua berjalan lokal di HP. Tidak ada server. Tidak ada API berbayar.**

---

## 0. Konsekuensi dari batasan "tanpa server"

Chatbot sungguhan butuh LLM, dan LLM hanya bisa jalan di server ATAU di dalam HP.
Karena server ditolak, ada dua jalan:

- **Jalan A — Rule-based / "pseudo-AI" (REKOMENDASI).** Refleksi, sapaan, dan insight
  dibuat dari **template + analisis data lokal** (kata kunci, tren mood, streak).
  Bukan ngobrol bebas, tapi terasa personal. Lokal, gratis, instan, privat, ukuran ~0.
- **Jalan B — On-device LLM (opsional, nanti).** Model kecil (Gemma 2B / Phi-3-mini)
  via `flutter_gemma` / MediaPipe LLM Inference. Bisa ngobrol, tapi +1–2 GB download,
  RAM besar, lambat di HP kelas bawah, kualitas terbatas.

> Keputusan: kerjakan **Jalan A** dulu. Ini memberi 90% efek "app terasa hidup"
> tanpa beban teknis apa pun. Jalan B bisa menyusul kalau benar-benar diinginkan.

---

## 1. Jalan A — "AI" lokal berbasis aturan

Semua "kecerdasan" dihitung dari box Hive yang sudah ada (`JournalEntry`, `TodoItem`).
Tidak ada panggilan jaringan.

### 1a. Mesin analisis lokal (`InsightEngine`)
Service baru yang membaca `StorageService` dan menghasilkan fakta:
- **Streak** — berapa hari berturut-turut ada jurnal (dari `createdAt`).
- **Mood dominan** — distribusi `moodIndex` dalam 7/30 hari terakhir.
- **Tag/kata tersering** — hitung frekuensi `tags` + kata penting dari `content`
  (buang stop-word Indonesia: "yang", "dan", "di", "ke", dst.).
- **Jam & hari produktif** — kapan paling sering menulis.
- **Tren mood** — naik/turun dibanding minggu lalu.

### 1b. Generator refleksi (`ReflectionEngine`)
Mengubah fakta jadi kalimat hangat memakai **template + variabel**, dengan persona terpilih.
Contoh aturan:

```
JIKA streak >= 3  → "Kamu sudah menulis {streak} hari berturut-turut 🌸 keren!"
JIKA tag tersering minggu ini = X → "Minggu ini kamu sering menulis tentang {X}."
JIKA mood turun dari minggu lalu → "Sepertinya minggu ini agak berat ya. Aku di sini kok."
JIKA entri baru disimpan & lelah → "Capek tapi tetap kamu kerjakan — itu konsisten namanya."
```

Variasikan kalimat (beberapa template per kondisi, dipilih acak) supaya tidak terasa kaku.
Hasil refleksi entri boleh disimpan di field opsional `JournalEntry.reflection`.

### 1c. "Chat" lokal (opsional, ringan)
Tanpa LLM, "chat" bisa berupa **percakapan terpandu**: AI mengajukan prompt reflektif
("Apa satu hal baik hari ini?"), user menjawab, AI menanggapi dengan template + simpan
jawaban sebagai jurnal. Ini bukan ngobrol bebas, tapi terasa interaktif dan tetap lokal.

---

## 2. Karakter pendamping (lokal)

Persona hanya mengubah **gaya kalimat template**, bukan model AI.

| ID | Nama | Peran | Gaya template |
|---|---|---|---|
| `aira` | Aira | Kakak penyemangat | Hangat, suportif, emoji lembut |
| `naya` | Naya | Teman santai | Kasual, akrab, ringan |
| `orion` | Orion | Mentor produktivitas | Tenang, fokus solusi |

Implementasi: tiap kondisi punya 3 varian kalimat (satu per persona). `selectedCompanion`
disimpan di prefs.

---

## 3. Penambahan model data (Hive)

```dart
// (opsional) chat_message.dart  (typeId: 2) — hanya jika bikin chat terpandu
@HiveType(typeId: 2)
class ChatMessage extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String companionId;
  @HiveField(2) bool fromUser;
  @HiveField(3) String text;
  @HiveField(4) DateTime createdAt;
}
```

Prefs baru di `StorageService`:
- `selectedCompanion` (default `'aira'`)

Field opsional di `JournalEntry`: `reflection` (String?) untuk cache refleksi lokal.

> Catatan: karena semua lokal, **tidak ada** consent privasi/server, tidak ada rate limit,
> tidak ada API key, tidak ada billing. Inilah keuntungan besar pendekatan ini.

---

## 4. Navigasi

Review menyarankan ganti **Stats → Chat**. Karena chat lokal terbatas, opsi lebih kuat:

- **Opsi 1 (disarankan):** Pertahankan 5 tab, ganti **Stats → Beranda diperkaya + Profil
  berisi statistik**. Tab baru **"Aira"** (pendamping) berisi refleksi harian + chat terpandu.
- **Opsi 2:** Ikuti review persis: tab Chat (terpandu) menggantikan Stats; Smart Stats pindah ke Profil.

```
Sekarang : Beranda | Jurnal | To-Do | Stats | Profil
Usulan   : Beranda | Jurnal | To-Do | Aira💜 | Profil   (statistik → Profil)
```

---

## 5. Beranda yang "hidup" (semua lokal)

Susunan baru (sesuai semangat review, tanpa AI server):
1. Sapaan persona + streak ("Aira: kamu sudah menulis 3 hari berturut-turut 🌸")
2. Mood hari ini (quick pick — sudah ada)
3. **Insight lokal** (1 kalimat dari `InsightEngine`)
4. To-Do hari ini
5. Aktivitas terbaru (sudah ada)

---

## 6. Smart Stats (semua lokal) — masuk ke Profil

- Grafik mood (sudah ada).
- **Kata/tag tersering** (word cloud sederhana / daftar).
- **Mood dominan** (persentase).
- **Hari & jam paling produktif.**
- **Achievement & streak.**

---

## 7. Achievement / streak (semua lokal)

Dihitung dari `createdAt`. Contoh badge: Jurnal 7 hari, 30 hari, 100 entri,
"Mood Tracker Master". Simpan status unlock di prefs. Pendorong retention #1 yang nyata.

---

## 7b. POC On-device LLM (sudah diimplementasi)

Status: **proof-of-concept terpasang.** Masuk lewat Profil → "Mode AI Offline (BETA)".

Berkas:
- `lib/services/ondevice_ai_service.dart` — pembungkus `flutter_gemma` (cek/unduh/muat/chat/hapus) + persona.
- `lib/screens/offline_ai_screen.dart` — UI alur: cek → unduh (progress) → muat → chat streaming.
- Init di `lib/main.dart`: `FlutterGemma.initialize(...)`.
- `android/app/build.gradle.kts`: `minSdk = maxOf(flutter.minSdkVersion, 24)`.

Model: **Gemma 3 1B IT int4** (~550 MB, format `.task`, MediaPipe).

### Cara menjalankan
Model Gemma di HuggingFace **gated**, jadi:
1. Buka https://huggingface.co/litert-community/Gemma3-1B-IT lalu setujui lisensinya.
2. Buat token di https://huggingface.co/settings/tokens.
3. Jalankan dengan token disuntik saat build:
   ```
   flutter run --dart-define=HUGGINGFACE_TOKEN=hf_xxxxx
   ```
4. Di app: Profil → Mode AI Offline → Unduh model → tunggu → chat.

### "Pilih Asisten + Chat di nav" (SELESAI)
- 5 karakter di `lib/models/companion.dart`: Aira, Naya (Tsundere), Orion, Luna, Atlas
  — masing-masing punya `accent` warna, `emoji`, `role`, `description`, `systemInstruction`.
- Avatar placeholder: `lib/widgets/companion_avatar.dart` (lingkaran gradien + emoji).
- Layar `lib/screens/companion_picker_screen.dart` ("Pilih Asisten").
- Pilihan tersimpan di `StorageService.selectedCompanionId`.
- Bottom nav diubah → **Beranda · Jurnal · Chat · Statistik · Profil** (To-Do dikeluarkan
  dari nav; `todo_screen.dart` masih ada, belum direlokasi). Chat di-push sebagai layar penuh.
- Beranda: baris "Karakter Asisten" + "Lihat semua". Profil: kartu "Ganti Karakter".
- `OfflineAiScreen` kini memakai karakter terpilih & ada tombol ganti karakter di AppBar.

### Batasan POC (sengaja belum dikerjakan)
- **Avatar masih placeholder** (emoji berwarna) — gambar anim asli menyusul.
- **To-Do** hilang dari bottom nav (perlu keputusan: relokasi ke Beranda/Profil atau buang).
- **Deteksi RAM** belum ada — baru ditampilkan sebagai peringatan teks. HP RAM < 4 GB
  bisa lambat/crash. Langkah lanjut: deteksi RAM via channel & sembunyikan fitur di HP lemah.
- Riwayat chat **belum disimpan** ke Hive (hilang saat keluar layar).
- Pemilih karakter (Aira/Naya/Orion) sudah ada di kode `Companion`, tapi UI masih kunci ke Aira.
- Belum ada manajemen "hapus model" di UI (ada di service: `OndeviceAiService.delete()`).
- Performa & kualitas Gemma 1B di HP kelas bawah perlu diuji di perangkat nyata.

## 8. Jalan B — On-device LLM (detail lanjutan)

Hanya jika benar-benar ingin ngobrol bebas tanpa server:
- Paket: `flutter_gemma` (MediaPipe) atau binding llama.cpp.
- Model: Gemma 2B / Phi-3-mini terkuantisasi (~1–2 GB), **diunduh saat pertama dipakai**
  (jangan dibundel ke APK — akan ditolak ukuran).
- Risiko: lambat/crash di HP RAM kecil, baterai, kualitas terbatas, kompleksitas tinggi.
- Saran: jadikan fitur opt-in "Mode AI Offline" yang jelas butuh unduhan besar.

---

## 9. Rencana bertahap (semua lokal, tanpa biaya)

1. **Streak + Achievement** — paling berdampak ke retention, paling murah.
2. **InsightEngine** (mesin analisis lokal).
3. **Smart Stats** di Profil (pakai InsightEngine).
4. **Beranda hidup** (sapaan + streak + 1 insight).
5. **ReflectionEngine + karakter pendamping** (template per persona).
6. **AI Reflection** otomatis di layar jurnal (pakai ReflectionEngine).
7. (Opsional) **Tab Aira** dengan chat terpandu.
8. (Opsional, jauh nanti) **Jalan B** on-device LLM.

> Semua langkah 1–7: lokal, gratis, privat, instan, tanpa menambah ukuran app berarti.
> Bisa langsung rilis ke Play Store.
```
