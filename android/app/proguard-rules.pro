# SiteStamp release (R8) keep rules.
#
# Android Gradle Plugin 9 ships a stricter R8. It strips parts of WorkManager and
# its Room database, which Google's ads SDK pulls in. Result: the app crashes at
# startup with "Failed to create an instance of androidx.work.impl.WorkDatabase".
# Keep these libraries intact.
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.startup.** { *; }
-keep class androidx.datastore.** { *; }
-dontwarn androidx.work.**
-dontwarn androidx.room.**
