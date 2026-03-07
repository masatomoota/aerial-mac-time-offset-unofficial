# Todo

## Plan

- [x] 現在のインポート実装とUI差分を確認する
- [x] エクスポートUIと出力形式を設計する
- [x] `Advanced` タブに設定エクスポート導線を追加する
- [x] 現在の表示系設定を plist に書き出す処理を実装する
- [x] ビルドまたは実行可能な検証を行い、結果を記録する

## Review

- `Advanced` タブに `Export Display...` ボタンを追加し、現在の表示系設定を plist として保存できるようにした
- エクスポート形式はインポートと同じキー集合を使う XML plist に統一し、別インストールでそのまま読み込めるようにした
- `xcodebuild -project Aerial.xcodeproj -scheme AerialApp build CODE_SIGNING_ALLOWED=NO` でビルド成功を確認した

## Follow-up Plan

- [x] エクスポート形式のトップレベルキー、型、内部 JSON 形式を洗い出す
- [x] Windows 版インポートで詰まりやすい互換ポイントを整理する
- [x] LLM 向けの表示設定フォーマット仕様書を `Documentation` に追加する
- [x] ドキュメント索引とタスク記録を更新する
- [x] 差分を確認して完了条件を見直す

## Follow-up Review

- `Documentation/DisplaySettingsTransferFormat.md` を追加し、XML plist 形式、メタデータ、キー一覧、enum raw value、JSON サブスキーマ、Apple 基準日付秒数を明記した
- Windows 版向けに `newDisplayDict`、`advancedMargins`、`fontName`、`shellScript`、`customDateFormat` / `customTimeFormat` の互換ルールを整理した
- `Documentation/README.md` に新仕様書へのリンクを追加した
- 今回はドキュメント追加のみのためビルドは未再実行。差分確認で内容整合性を検証する

## Build Plan

- [x] 実行可能成果物の対象スキームと生成物の種類を確認する
- [x] `AerialApp` を Release でビルドして `.app` を生成する
- [x] `Aerial` を Release でビルドして `.saver` を生成する
- [x] 生成されたバイナリ形式と出力先を確認する
- [x] 結果と既知の警告を記録する

## Build Review

- `xcodebuild -project Aerial.xcodeproj -scheme AerialApp -configuration Release -derivedDataPath build/DerivedData-AerialApp CODE_SIGNING_ALLOWED=NO CONFIGURATION_BUILD_DIR="$PWD/build/Release/AerialApp" build` で `build/Release/AerialApp/AerialApp.app` を生成した
- `xcodebuild -project Aerial.xcodeproj -scheme Aerial -configuration Release -derivedDataPath build/DerivedData-AerialSaver CODE_SIGNING_ALLOWED=NO CONFIGURATION_BUILD_DIR="$PWD/build/Release/Aerial" build` で `build/Release/Aerial/Aerial.saver` を生成した
- `file` で `AerialApp.app/Contents/MacOS/AerialApp` は `arm64` 実行ファイル、`Aerial.saver/Contents/MacOS/Aerial` は `x86_64` / `arm64` の universal bundle であることを確認した
- ビルドはいずれも成功。既知の非ブロッカー警告として SwiftLint スクリプトの毎回実行、既存ソースの deprecation / Sendable / XIB notice、`Aerial` 側の `CFBundleIdentifier` 大文字小文字不一致警告が出ている
- 今回の成果物は `CODE_SIGNING_ALLOWED=NO` で生成しているため未署名

## Handoff Plan

- [x] handoff の記録先と同期先ブランチを確認する
- [x] 今回の変更・検証・成果物を handoff に整理する
- [x] handoff を含めてコミットし、GitHub に push する

## Handoff Review

- `tasks/handoff.md` を追加し、変更要約、検証コマンド、成果物、既知警告、次アクションを整理した
- 現在の同期先は `origin/master` であることを確認した
- この後の GitHub 同期結果はコミットハッシュと push 結果で確認する
