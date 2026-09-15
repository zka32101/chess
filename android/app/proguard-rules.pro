# Phase L-3: ProGuard Obfuscation Rules for Chess Tactics Master
# These rules optimize and obfuscate the Android app while preserving functionality

# ========== Basic Optimization Rules ==========

# Optimization configuration
-optimizationpasses 5
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-allowaccessmodification
-dontpreverify

# ========== Preserve Application Entry Point ==========

-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends androidx.fragment.app.Fragment
-keep public class * extends androidx.appcompat.app.AppCompatActivity

-keepclasseswithmembernames class * {
    native <methods>;
}

# ========== Preserve Flutter/Dart Classes ==========

# Keep Dart interop classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# ========== Preserve Firebase Classes ==========

-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ========== Preserve Serialization Classes ==========

# JSON serialization (Freezed, json_serializable)
-keep class com.google.gson.** { *; }
-keep class com.google.gson.stream.** { *; }
-keepclassmembers class * {
    *** *;
}

# Preserve model classes (Chess-specific)
-keep class com.example.chess_tactics_master.models.** { *; }
-keep class com.example.chess_tactics_master.src.models.** { *; }

# ========== Preserve Android Framework Classes ==========

-keep public class android.app.** { *; }
-keep public class android.content.** { *; }
-keep public class android.widget.** { *; }
-keep public class androidx.** { *; }

# ========== Method Preservation for Reflection ==========

-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}

-keepclasseswithmembers class * {
    public <init>();
}

# ========== View Constructors for XML Layout Inflation ==========

-keepclasseswithmembers class * {
    public <init>(android.content.Context);
}

# ========== Suppress Warnings ==========

-dontwarn android.**
-dontwarn androidx.**
-dontwarn com.google.android.material.**
-dontwarn java.lang.invoke.**
-dontwarn java.nio.file.**
-dontwarn sun.misc.**

# ========== Optimization-Specific Rules ==========

# Remove logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Allow aggressive string concatenation optimization
-optimizations !code/simplification/arithmetic,!code/simplification/cast

# ========== Package Preservation ==========

# Keep package names intact for proper functioning
-keeppackagenames com.example.chess_tactics_master.**

# ========== Chess Engine Classes ==========

# Preserve chess engine package
-keep class chess.** { *; }
-keep interface chess.** { *; }

# ========== Database Classes (SQLite) ==========

-keep class android.database.sqlite.** { *; }
-keep class com.example.chess_tactics_master.db.** { *; }

# ========== Utility & Helper Classes ==========

# Keep classes with annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# ========== Enums ==========

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ========== Parcelable Classes ==========

-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# ========== R Classes (Resources) ==========

-keepclassmembers class **.R$* {
    public static <fields>;
}

# ========== Size Optimization ==========

# Obfuscate class names
-repackageclasses 'com.example.chess'

# Shorten member names (but preserve functionality)
-obfuscationdictionary proguard-obfuscation.txt

# Use shorter names for obfuscation
-classobfuscationdictionary proguard-obfuscation.txt
-packageobfuscationdictionary proguard-obfuscation.txt

# ========== Exception Handling ==========

-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ========== Additional Optimization ==========

# Merge inner classes
-mergeinterfacesaggressively
-allowaccessmodification
-mergeallclasses

# ========== Chess-Specific Preservation ==========

# Preserve main app class and key services
-keep public class com.example.chess_tactics_master.ChessApp { *; }
-keep public class com.example.chess_tactics_master.MainActivity { *; }
-keep public class com.example.chess_tactics_master.src.services.** { *; }
-keep public class com.example.chess_tactics_master.src.providers.** { *; }

# ========== Performance Monitoring ==========

# Preserve performance monitor classes
-keep class com.example.chess_tactics_master.src.utils.PerformanceMonitor { *; }
-keep class com.example.chess_tactics_master.src.utils.performance_monitor.** { *; }

# ========== Testing Support ==========

# Keep test-related classes if building for testing
-keep class com.example.chess_tactics_master.** extends junit.framework.TestCase { *; }
-keep interface com.example.chess_tactics_master.** { *; }
