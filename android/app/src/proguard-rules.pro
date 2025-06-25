# Keep share_plus classes
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class androidx.core.content.FileProvider { *; }
-keep class androidx.core.content.FileProvider$** { *; }

# Keep Syncfusion XlsIO classes
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# Keep Flutter plugins
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep XML parsing classes
-keep class android.content.res.** { *; }
-keep class org.xmlpull.** { *; }
-dontwarn org.xmlpull.**

# Keep reflection classes used by Excel generation
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep FileProvider paths
-keep class * extends androidx.core.content.FileProvider

# Prevent obfuscation of classes used by share_plus
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}