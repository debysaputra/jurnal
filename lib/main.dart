import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/root_screen.dart';
import 'services/ads_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  // Inisialisasi mesin AI on-device (POC). Token HF opsional untuk model gated,
  // disuntik saat build: --dart-define=HUGGINGFACE_TOKEN=hf_xxx
  const hfToken = String.fromEnvironment('HUGGINGFACE_TOKEN');
  await FlutterGemma.initialize(
    huggingFaceToken: hfToken.isEmpty ? null : hfToken,
  );
  await StorageService.instance.init();
  await NotificationService.instance.init();
  // Init AdMob (non-blocking — banner widget akan inisialisasi ulang bila perlu)
  unawaited(AdsService.instance.init());
  if (StorageService.instance.reminderEnabled) {
    await NotificationService.instance.scheduleDaily(
      StorageService.instance.reminderHour,
      StorageService.instance.reminderMinute,
    );
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyJurnalApp());
}

class MyJurnalApp extends StatelessWidget {
  const MyJurnalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyJurnal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RootScreen(),
    );
  }
}
