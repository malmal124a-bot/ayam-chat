# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# Google Play Core (referenced by Flutter deferred components, not used)
-dontwarn com.google.android.play.core.**

# Agora RTC Engine
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# Supabase / GoTrue / PostgREST
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**
