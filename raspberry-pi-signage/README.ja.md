# aerial-signage

`aerial-signage` は Raspberry Pi 4/5 を、Apple Aerial 動画を全画面でループ再生するデジタルサイネージにします。時計オーバーレイは実時刻に `AERIAL_CLOCK_OFFSET_MINUTES` を加えた時刻を表示し、未設定時は macOS 版フォークと同じ +10 分です。

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
| `AERIAL_CLOCK_ENABLED` | `1` で時計表示、`0` で非表示。 | `1` |
| `AERIAL_CLOCK_OFFSET_MINUTES` | 実時刻に加える分数。負数も可能。 | `10` |
| `AERIAL_CLOCK_FORMAT` | `24h`、`12h`、`custom`。 | `24h` |
| `AERIAL_CLOCK_SECONDS` | `1` で秒を表示。 | `0` |
| `AERIAL_CLOCK_HIDE_AMPM` | `12h` 形式で `1` にすると AM/PM を非表示。 | `0` |
| `AERIAL_CLOCK_CUSTOM_FORMAT` | `custom` 形式で使う `strftime` 文字列。 | `%H:%M` |
| `AERIAL_CLOCK_CORNER` | `topLeft`、`topRight`、`bottomLeft`、`bottomRight`、`center`。 | `bottomRight` |
| `AERIAL_CLOCK_FONT_SIZE` | 1920x1080 基準の ASS フォントサイズ。 | `48` |
| `AERIAL_CLOCK_FONT` | 任意のフォント名。空なら mpv 既定。 | 空 |
| `AERIAL_CLOCK_MARGIN` | 1920x1080 基準の端からの余白ピクセル。 | `60` |
| `AERIAL_CLOCK_COLOR` | 時計色。`RRGGBB`。 | `FFFFFF` |
| `AERIAL_QUALITY` | `1080-sdr`、`1080-hdr`、`4k-sdr`、`4k-hdr`、`1080-h264`。 | `1080-sdr` |
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
