# Frozen assignment bridge release fence

This change is intentionally release-ordered because the native SDKs parse the
backend assignment value before Sandwich receives it:

1. Publish Android SDK `9.8.0` and iOS SDK `6.15.0` with the native `Frozen`
   assignment enum.
2. Publish Sandwich `7.13.0`, which requires those native versions and maps
   `Frozen` to the cross-platform `"frozen"` value.
3. Upgrade React Native, Flutter, Cordova, Capacitor and Unity to Sandwich
   `7.13.0`.

Until all three steps are published and present in the production compatibility
matrix, Configurator's type-3 write gate remains fail-closed.
