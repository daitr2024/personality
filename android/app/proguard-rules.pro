# ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**

# Gson TypeToken — required by flutter_local_notifications
# Prevents R8 from stripping generic type info used by Gson's TypeToken
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Home Widget
-keep class com.daitr2024.personalityai.HomeWidgetProvider { *; }
-keep class com.daitr2024.personalityai.** { *; }
-keep class es.antonborri.home_widget.** { *; }
-dontwarn es.antonborri.home_widget.**

