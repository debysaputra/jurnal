# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# AdMob / Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# flutter_local_notifications (Tiramisu / Gson related)
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * extends com.google.gson.TypeAdapterFactory
-keep class * extends com.google.gson.JsonSerializer
-keep class * extends com.google.gson.JsonDeserializer

# Hive
-keep class hive.** { *; }
-keepclassmembers class * extends hive.HiveObject { *; }

# image_picker / camera
-keep class androidx.camera.** { *; }
-keep class androidx.lifecycle.DefaultLifecycleObserver

# Play core (untuk deferred components / split install) — wajib karena
# build modern menarik referensi ini.
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**

# Kotlin metadata
-keep class kotlin.Metadata { *; }
