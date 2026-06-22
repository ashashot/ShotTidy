# Xcode Security Settings

Security build settings decisions for **ShotTidy** (iOS app, macOS app `ShotTidierMac`,
Share Extension, Widget Extension). Pure-Swift codebase.

## Enabled settings

- `ENABLE_ENHANCED_SECURITY` to `YES` (project level, Debug + Release).
  Cascades `ENABLE_POINTER_AUTHENTICATION = YES` (arm64e), stack zero-init,
  security compiler warnings, and typed allocators to all targets.
- `GCC_WARN_ABOUT_RETURN_TYPE` to `YES_ERROR` (pre-existing, project level).

### Enhanced Security — entitlements (per supported target)

Applied to the two application targets (`ShotTidy` iOS, `ShotTidierMac` macOS).
Both platforms support arm64e, so no `ENABLE_POINTER_AUTHENTICATION = NO`
override was needed. The project has no binary/SPM dependencies, so arm64e
linking is safe.

Keys added to `ShotTidy/ShotTidy.entitlements` and
`ShotTidierMac/ShotTidierMac.entitlements`:

- `com.apple.security.hardened-process` = `true` (main toggle)
- `com.apple.security.hardened-process.enhanced-security-version-string` = `"2"`
- `com.apple.security.hardened-process.hardened-heap` = `true`
- `com.apple.security.hardened-process.dyld-ro` = `true`
- `com.apple.security.hardened-process.platform-restrictions-string` = `"2"`

**Required follow-up (Apple Developer account):** the App ID provisioning
profile must include the Enhanced Security capability. On the first build in
Xcode with the team account signed in, automatic signing registers it; or
enable it manually on the App ID in the developer portal. Headless `xcodebuild`
signing fails until then (the code itself compiles cleanly as arm64e — verified
with `CODE_SIGNING_ALLOWED=NO` on both targets).

## Skipped targets

- `ShotTidyShare` and `ShotTidyWidgetExtension`: product type
  `com.apple.product-type.app-extension` is not in the Enhanced Security
  supported product-type list, so entitlements were not applied. They still
  inherit the project-level build-setting cascade (harmless; iOS supports arm64e).

## Disabled settings

- None.

## Deferred

- `com.apple.security.hardened-process.checked-allocations` (Hardware Memory
  Tagging / MTE): default-OFF. Requires M5-class Apple silicon or later.
  Revisit with a soft-mode rollout when targeting that hardware.

## Not applicable

- Basic Clang safety warnings (`GCC_WARN_UNINITIALIZED_AUTOS`,
  `CLANG_WARN_IMPLICIT_FALLTHROUGH`, `CLANG_ANALYZER_SECURITY_*`, etc.) and
  C/C++ bounds-safety models: the codebase is pure Swift, so these C/ObjC/C++
  diagnostics do not apply.
