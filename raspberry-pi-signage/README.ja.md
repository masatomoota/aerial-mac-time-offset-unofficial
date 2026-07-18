# aerial-signage

`aerial-signage` は Raspberry Pi 4/5 を、Apple Aerial 動画を全画面でループ再生するデジタルサイネージにします。テキストは Windows 版に合わせた 4 行モデルで、9 点の共有 Position、Random 配置、行ごとの Time-Date / Information / Video Name / Message を扱えます。すべての Time-Date 行は同じ表示時刻（`now + AERIAL_CLOCK_OFFSET_MINUTES`）を使います。

## HEVC を標準にする理由

標準画質は HEVC の `1080-sdr` です。Raspberry Pi 4 と Pi 5 はどちらも 4K HEVC をハードウェアデコードできます。Pi 5 は H.264 のハードウェアデコードを持たず、Pi 4 の H.264 ハードウェアデコードも 1080p までなので、サイネージ用途の標準は HEVC が適しています。

## クイックスタート

```bash
sudo ./install.sh
sudo editor /etc/aerial-signage/aerial-signage.conf
sudo -u "$USER" AERIAL_CONFIG=/etc/aerial-signage/aerial-signage.conf /opt/aerial-signage/bin/aerial-fetch --limit 10
sudo reboot
```

表示時刻のずれは `AERIAL_CLOCK_OFFSET_MINUTES` で設定します。動画は大きいため、初期設定中は小さな `--limit` を指定してください。

## 設定

設定ファイルは shell の `KEY=VALUE` 形式です。インストール先は `/etc/aerial-signage/aerial-signage.conf` です。

| 変数 | 意味 | 既定値 |
| --- | --- | --- |
| `AERIAL_TEXT_POSITION` | 共有 Position。`topLeft`、`topCenter`、`topRight`、`bottomLeft`、`bottomCenter`、`bottomRight`、`left`、`right`、`screenCenter`、`random`。 | `bottomLeft` |
| `AERIAL_TEXT_RANDOM_INTERVAL` | Random 配置の変更間隔（秒）。 | `30` |
| `AERIAL_TEXT_MAX_WIDTH` | Windows 互換の最大幅（%）。 | `50` |
| `AERIAL_TEXT_FONT` / `AERIAL_TEXT_SIZE` / `AERIAL_TEXT_COLOR` | グローバルのフォント、Windows 互換サイズ倍率、`RRGGBB` 色。 | `Segoe UI` / `2` / `FFFFFF` |
| `AERIAL_CLOCK_OFFSET_MINUTES` | すべての Time-Date 行に加える分数。負数も可能。 | `0` |
| `AERIAL_LINE{1..4}_TYPE` | `none`、`timedate`、`information`（POI/Label/Filename）、`videoname`、`message`。 | `none` |
| `AERIAL_LINE{1..4}_FORMAT` | `timedate` 行の Moment.js 形式。対応 token: `YYYY YY MMMM MMM MM M DD D dddd ddd dd d Do HH H hh h mm m ss s A a`。 | `hh:mm:ss` |
| `AERIAL_LINE{1..4}_TEXT` | メッセージ本文。改行はリテラル `\n`。 | 空 |
| `AERIAL_LINE{1..4}_INFO_MODE` | `information` 行で使う `poi`、`accessibilityLabel`、`filename`。 | `poi` |
| `AERIAL_LINE{1..4}_USE_DEFAULT_FONT` | `1` でグローバル Text Options、`0` で行ごとのフォント/サイズ倍率/色。 | `1` |
| `AERIAL_QUALITY` | `1080-sdr`、`1080-hdr`、`4k-sdr`、`4k-hdr`、`1080-h264`。 | `1080-sdr` |
| `AERIAL_SOURCE` | `classic63`、`tvos16`、`community`。Web UI では Windows と同じ 114 本セットの `tvos16` を推奨。 | `classic63` |
| `AERIAL_MANIFEST_URL` | JSON マニフェスト URL。 | Apple Aerial 版（`sylvan.apple.com`） |
| `AERIAL_CACHE_DIR` | `.mov` の保存先。 | `/var/lib/aerial-signage/videos` |
| `AERIAL_PLAYLIST` | `aerial-fetch` が生成する mpv プレイリスト。 | `/var/lib/aerial-signage/playlist.txt` |
| `AERIAL_VIDEO_LIMIT` | `0` は全件、`N` は先頭 `N` 件のみ。 | `0` |
| `AERIAL_STRICT_QUALITY` | `1` で `AERIAL_QUALITY` の完全一致のみ取得し、他コーデックへフォールバックしない（Pi 3 で使用）。 | `0` |
| `AERIAL_SHUFFLE` | `1` でシャッフル再生。 | `1` |
| `AERIAL_MPV_VO` | mpv の video output。 | `gpu` |
| `AERIAL_MPV_GPU_CONTEXT` | Pi のコンソールでは `drm`。デスクトップ検証では `auto`。 | `drm` |
| `AERIAL_MPV_HWDEC` | Pi の HEVC ハードウェアデコードでは `drm-copy`。デスクトップ検証では `auto`。 | `drm-copy` |
| `AERIAL_MPV_EXTRA` | 追加の mpv フラグ。 | 空 |

macOS DisplaySettings plist の raw enum、Windows UI 値、Pi env 文字列の対応は `docs/display-settings-mapping.md` にまとめています。Web UI では macOS `AerialDisplaySettings.plist` の読み込み、Windows 互換 `config.json` の import/export、`/etc/aerial-signage/profiles/` 以下の動画選択 Profiles 管理ができます。

## Raspberry Pi 3（実験的対応）

Pi 3（VideoCore IV）には **HEVC ハードウェアデコードが無く**、H.264 ハードウェアデコードは 1080p
まで、HDMI 出力も 1080p まで、CPU での HEVC ソフトデコードも実時間では不可能です。そのため既定の
HEVC 画質は動作しません。H.264 版を厳格モードで使ってください（HEVC への暗黙フォールバックを防ぎ
ます）:

```
AERIAL_QUALITY=1080-h264
AERIAL_STRICT_QUALITY=1
AERIAL_MPV_HWDEC=v4l2m2m-copy
```

補足: Raspberry Pi OS **Lite** ならメモリ 1GB で足ります。24 時間運用ではヒートシンクを付けて
ください。Bookworm 上の `v4l2m2m` H.264 経路は Pi 3 実機で未検証のため実験的扱いです。新規購入
なら Pi 4/5 を推奨します。

## 動画ソース

既定では `aerial-fetch` が本物の Apple Aerial 動画一式（63 本、`sylvan.apple.com` から配信）を、
コミュニティ管理のマニフェストミラー経由で取得します。そのマニフェストのスナップショットを
`manifest/entries.json` に同梱しており、ミラーに到達できない場合は自動的にこれを使います。

**Apple Root CA（Linux 必須）:** `sylvan.apple.com` は Apple の*プライベート*ルート CA で署名されて
います。macOS/iOS/tvOS には最初から入っていますが Linux の信頼ストアには無いため、そのままでは
`CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate` で全ダウンロードが失敗します。
`install.sh` はこのルートを自動導入します（Apple から公的CA検証済みの接続で取得し、SHA-256 で照合）。
`--no-apple-ca` で無効化できます。コミュニティ版マニフェストを使う場合はこの CA は不要です。

Apple が URL を変更した場合は、`AERIAL_MANIFEST_URL` を GitHub ホストのコミュニティ版
（本数は少ないが非常に安定）へ切り替えてください。

```
AERIAL_MANIFEST_URL=https://raw.githubusercontent.com/glouel/AerialCommunity/master/entries.json
```

## 手動実行

先に動画を取得します。

```bash
AERIAL_CONFIG=/etc/aerial-signage/aerial-signage.conf /opt/aerial-signage/bin/aerial-fetch --limit 10
```

その後、プレイヤーを起動します。

```bash
AERIAL_CONFIG=/etc/aerial-signage/aerial-signage.conf /opt/aerial-signage/bin/aerial-signage
```

Pi 以外のデスクトップで試す場合は次のようにします。

```bash
AERIAL_MPV_GPU_CONTEXT=auto AERIAL_MPV_HWDEC=auto /opt/aerial-signage/bin/aerial-signage
```

## パフォーマンスチューニング（実機 Pi 4 + 4K TV / Trixie / mpv 0.40 での実測）

実デプロイで遭遇した症状と原因・対策：

| 症状 | 原因 | 対策 |
| --- | --- | --- |
| 約3fps・CPU高負荷 | `hwdec=drm-copy` がタイル形式10bit HEVCを毎フレームCPUコピー | ゼロコピー化 or H.264 |
| コーデックに関係なく約15fps | 旧 `--vo=gpu` レンダラの表示限界 | `AERIAL_MPV_VO=gpu-next` |
| `gpu-next` で**紫一色** | libplacebo が Pi のタイル形式（`rpi4_10` SAND）10bit を読めない | H.264 版を再生する |
| 30fps 付近でカクつく | 29.97fps 素材と 60.00Hz vsync のリズム不一致 | `--video-sync=display-resample` |
| 4K ディスプレイで極端に遅い | Pi 4 GPU が毎フレーム 1080p→4K をシェーダ拡大 | `--drm-mode=1920x1080`（拡大はTV任せ） |

**Pi 4 での確定動作設定**（10秒間ドロップ0・CPU約17%を実測）:

```
AERIAL_QUALITY=1080-h264
AERIAL_STRICT_QUALITY=1
AERIAL_MPV_VO=gpu-next
AERIAL_MPV_HWDEC=v4l2m2m-copy
AERIAL_MPV_EXTRA="--drm-mode=1920x1080 --video-sync=display-resample"
```

これは macOS 版 Aerial の H.264/HEVC 選択と同じ発想です。Pi 4 では H.264 版を選ぶ —
8bit リニア形式なのでタイル10bit の表示問題を根本から回避でき、専用 H.264 ハードデコーダで
1080p は余裕です（HEVC はデコード自体は 84fps と高速で、ボトルネックは**タイル10bitの表示**でした）。

## トラブルシューティング

黒画面になる場合は、mpv が DRM/KMS を所有できていない可能性があります。デスクトップではなくコンソールへ起動し、tty1 で実行し、`AERIAL_MPV_GPU_CONTEXT=drm` を使ってください。

ハードウェアデコードが効かない場合は、HEVC の画質を選んでいること、`AERIAL_MPV_HWDEC=drm-copy`、サービスユーザーが `video` と `render` グループに入っていることを確認してください。

動画は大きく、1 本あたりおよそ 265-354 MB です。検証中は `AERIAL_VIDEO_LIMIT` または `aerial-fetch --limit N` を使ってください。

ログ確認:

```bash
journalctl -u aerial-signage
journalctl -u aerial-fetch
```

## クレジット

Apple Aerial 動画の権利は Apple にあります。このプロジェクトは upstream Aerial screensaver に着想を得ており、コミュニティ管理のマニフェストミラーを利用します。このディレクトリ内のコードは MIT ライセンスです。
