# Handoff

## Summary

- `Advanced` タブに `Import Display...` と `Export Display...` を追加
- 表示系設定のみを XML plist でエクスポートし、同じキー集合で再インポートできるように実装
- Windows 版や LLM 実装者向けに、表示設定転送フォーマット仕様書を追加
- Release ビルドで `AerialApp.app` と `Aerial.saver` の生成を確認

## Main Changes

### UI and logic

- `Resources/MainUI/Settings panels/AdvancedViewController.swift`
  - `Import Display...` / `Export Display...` ボタンを追加
  - 表示設定エクスポート処理を追加
  - 表示設定のインポート/エクスポート対象キーを共通化
  - エクスポートファイルに `_AerialDisplaySettingsExport=true` と `_AerialDisplaySettingsVersion=1` を付与

### Documentation

- `Documentation/DisplaySettingsTransferFormat.md`
  - XML plist の外形
  - トップレベルキー一覧
  - enum raw value
  - JSON-in-string payload (`layers`, `Layer*`, `advancedMargins`)
  - Apple reference date 基準の数値日付
  - Windows 向け互換ルール

- `Documentation/README.md`
  - 上記仕様書へのリンクを追加

### Task records

- `tasks/todo.md`
- `tasks/lessons.md`

## Verification

- `xcodebuild -project Aerial.xcodeproj -scheme AerialApp build CODE_SIGNING_ALLOWED=NO`
- `xcodebuild -project Aerial.xcodeproj -scheme AerialApp -configuration Release -derivedDataPath build/DerivedData-AerialApp CODE_SIGNING_ALLOWED=NO CONFIGURATION_BUILD_DIR="$PWD/build/Release/AerialApp" build`
- `xcodebuild -project Aerial.xcodeproj -scheme Aerial -configuration Release -derivedDataPath build/DerivedData-AerialSaver CODE_SIGNING_ALLOWED=NO CONFIGURATION_BUILD_DIR="$PWD/build/Release/Aerial" build`
- `file build/Release/AerialApp/AerialApp.app/Contents/MacOS/AerialApp`
- `file build/Release/Aerial/Aerial.saver/Contents/MacOS/Aerial`

## Build Artifacts

- App bundle: `build/Release/AerialApp/AerialApp.app`
- Screensaver bundle: `build/Release/Aerial/Aerial.saver`

## Known Warnings

- SwiftLint の Run Script が outputs 未設定のため毎回実行される
- 既存コード由来の deprecation / Sendable / XIB notice が残っている
- `Aerial` ターゲットで `CFBundleIdentifier` の大文字小文字不一致警告が出る
- Release 成果物は `CODE_SIGNING_ALLOWED=NO` のため未署名

## Next Useful Actions

- 必要なら署名して配布用 zip を作成
- Windows 版に `DisplaySettingsTransferFormat.md` を元に importer を実装
