[app]

# (str) Title of your application
title = Candle

# (str) Package name
package.name = candle

# (str) Package domain (needed for android/ios packaging)
package.domain = de.freegroup

# (str) Source code where the main.py lives
source.dir = ./src

source.include_exts = py,png,jpg,kv,atlas,mp3,mo,po

# (list) Application requirements
# Specify your app's requirements here. Start with the basics: python3 and kivy.
requirements = 
    python3,
    kivy,
    openssl,
    gpxpy,
    android,
    kivy_garden.mapview,
    bleak,
    typing_extensions, 
    async_to_sync, 
    async-timeout,
    https://github.com/HyTurtle/plyer/archive/master.zip

# (str) Application version
version = 0.1

# (list) Supported orientations
orientation = portrait

#
# Android specific
#

p4a.local_recipes = ./recipes


# (bool) Indicate if the application should be fullscreen or not
fullscreen = 1

# (list) Permissions
android.permissions = 
    BLUETOOTH_ADMIN,
    BLUETOOTH,
    BLUETOOTH_SCAN,
    BLUETOOTH_CONNECT,
    INTERNET,
    ACCESS_BACKGROUND_LOCATION,
    ACCESS_FINE_LOCATION,
    ACCESS_COARSE_LOCATION,
    VIBRATE,
    WRITE_EXTERNAL_STORAGE,
    READ_EXTERNAL_STORAGE

# (int) Target Android API
android.api = 33

# (int) Minimum API your APK / AAB will support
android.minapi = 21

# (str) Android NDK version to use
android.ndk = 25b

# (list) The Android archs to build for
android.archs = arm64-v8a

[buildozer]

# (int) Log level
log_level = 2

# (int) Display warning if buildozer is run as root
warn_on_root = 1
