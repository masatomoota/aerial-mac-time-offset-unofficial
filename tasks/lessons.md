# Lessons

- 現時点では、このプロジェクト固有の教訓は未記録。
- 設定インポートは plist 全体の置換ではなく、表示系のキーだけを選択コピーする。キャッシュ、更新、デバッグ系の設定は巻き込まない。
- 設定インポートを追加したら、同じキー集合を使うエクスポートも対で用意する。フォーマットを分けず XML plist で往復可能にする。
- 表示設定を他実装へ共有する時は、plist の外形だけでなく JSON 文字列化された入れ子データ、enum raw value、Apple 基準日付秒数、プラットフォーム依存キーの扱いまで仕様化する。
- 実行可能成果物が必要な時は `AerialApp` と `Aerial` を別の `derivedDataPath` / `CONFIGURATION_BUILD_DIR` に Release ビルドすると、`AerialApp.app` と `Aerial.saver` を衝突なく確定パスで回収できる。
