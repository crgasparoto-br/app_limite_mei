# Regras ProGuard para Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Play Core (deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Supabase
-keep class io.supabase.** { *; }
-keepclassmembers class io.supabase.** { *; }

# Keep genérico para reflection
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
