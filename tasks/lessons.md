# Lessons

- 現時点では、このプロジェクト固有の教訓は未記録。
- 設定インポートは plist 全体の置換ではなく、表示系のキーだけを選択コピーする。キャッシュ、更新、デバッグ系の設定は巻き込まない。
- 設定インポートを追加したら、同じキー集合を使うエクスポートも対で用意する。フォーマットを分けず XML plist で往復可能にする。
- 表示設定を他実装へ共有する時は、plist の外形だけでなく JSON 文字列化された入れ子データ、enum raw value、Apple 基準日付秒数、プラットフォーム依存キーの扱いまで仕様化する。
- 実行可能成果物が必要な時は `AerialApp` と `Aerial` を別の `derivedDataPath` / `CONFIGURATION_BUILD_DIR` に Release ビルドすると、`AerialApp.app` と `Aerial.saver` を衝突なく確定パスで回収できる。

## Raspberry Pi サイネージ移植

- macOS 版は `ScreenSaver.framework` / AppKit / AVFoundation 依存で Linux ネイティブ移植は不可。機能（Aerial ループ + オフセット時計）を **再現** する方針が正解。フォーク固有機能は環境変数名 `AERIAL_CLOCK_OFFSET_MINUTES`（既定 10 分）まで揃えて連続性を持たせた。
- Pi のコーデック事実は一次情報（公式スペック）で確認する。**Pi 4/Pi 5 とも 4K HEVC を HW デコード**、Pi 5 は H.264 HW デコード非搭載。よって HEVC が既定。Chromium は Pi で HEVC を HW デコードできないため browser-kiosk は不採用、mpv + systemd(DRM/KMS, `hwdec=drm-copy`) を採用。
- Aerial 動画は `entries.json` マニフェスト経由。既定は Apple 実データ（kopiro ミラー → `sylvan.apple.com`）、オフラインフォールバックを同梱、GitHub ホストの community 版を代替として文書化。Apple CDN は素の `urllib`＋ブラウザ UA を受け付ける（HTTP 206 で確認）。
- Lua OSD 時計は「純粋ロジック（`aerial_clock.lua`）＋ mpv グルー（`clock-overlay.lua`）」に分離すると、mpv 無しで `lua` 単体テストでき、実 mpv でも require パスが通る（単一ファイル `--script` では `mp.get_script_directory()` が nil になり得るので `debug.getinfo` フォールバックが必要）。
- codex CLI に機械作業を委譲すると Claude 週次枠を節約できる。`codex-code-mode-host` 欠落時は ChatGPT.app 同梱バイナリへ symlink で復旧。`codex exec --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check -C <dir>` で非対話実行。
- 同一 config を bash `source` と自前パーサの両方で読む設計は乖離バグの温床。導入するなら (1) source 前に「安全な単一代入行」だけ通す全行マッチ検証、(2) パーサ側は bash 挙動（コメント・引用・$VAR スコープ展開）へ明示的に合わせ、(3) 両者で拒否/受理が一致することをテストで固定する。`KEY=x; cmd` / `KEY=x cmd` は代入に見えて source で実行される注入経路。
- root が実行するコードパス（systemd timer → /opt 配下）は `cp -a` の所有権持ち込みに注意。インストール後に `chown root:root` + `chmod go-w` で正規化し、サービスには `User=` を明示する。
- tty1 kiosk は `Conflicts=getty@tty1.service` + `After=` + `TTYReset/TTYVHangup/TTYVTDisallocate` が標準パターン（無いと getty と奪い合い黒画面）。
- レビューは「発見(複数モデル) → 検証(懐疑エージェント) → 管理者裁定 → 修正 → **修正差分の独立再レビュー**」まで回すと、修正自体のバグ（今回3件）まで拾える。
