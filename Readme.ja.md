<p align="center">
  <img src="https://cloud.githubusercontent.com/assets/499192/10754100/c0e1cc4c-7c95-11e5-9d3b-842d3acc2fd5.gif">
</p>

# Aerial for Mac Time Offset (非公式)

[English README](./Readme.md)

> このリポジトリは [JohnCoates/Aerial](https://github.com/JohnCoates/Aerial) の非公式フォークです。  
> 画面上の時計表示に手動オフセットを適用する機能を追加しています。  
> 公式Aerialメンテナーとは無関係で、承認・サポートも受けていません。

Aerial は Apple TV の空撮スクリーンセーバーをもとにした Mac 用スクリーンセーバーです（macOS 10.12 以降）。ニューヨーク、サンフランシスコ、ハワイ、中国などの映像を表示します。2.0.0 以降は Joshua Michaels 氏と Hal Bergman 氏が共有した動画も含まれます。

Aerial は完全にオープンソースで、開発への貢献を歓迎します。

このリポジトリは**開発用途専用**です。

## このFork固有機能: 手動の時計オフセット

- 環境変数: `AERIAL_CLOCK_OFFSET_MINUTES`
- 例: `AERIAL_CLOCK_OFFSET_MINUTES=-540`
- 未設定または不正値時の挙動: `10` 分を既定値として使用（このForkの現行既定動作）

Aerial は 2.3.0 以降、[OpenWeather](https://openweathermap.org) の提供により、現在の天気と予報の表示にも対応しています。

![openweather_logo](https://user-images.githubusercontent.com/37544189/115738975-d689bf80-a38d-11eb-809b-fbb019e6ed08.png)

オープンソースプロジェクトへの支援をいただいている [OpenWeather](https://openweathermap.org) に感謝します。

# 公式プロジェクト

- 公式upstreamリポジトリ: [JohnCoates/Aerial](https://github.com/JohnCoates/Aerial)
- 公式サイト: [aerialscreensaver.github.io](https://aerialscreensaver.github.io)
- Windows向けFork: [OrangeJedi/Aerial](https://github.com/OrangeJedi/Aerial)  
- Linux向け実装: [graysky2/xscreensaver-aerial](https://github.com/graysky2/xscreensaver-aerial/)

## Aerialについて

Aerial は 2015 年に John Coates 氏（[Twitter](https://twitter.com/JohnCoatesDev), [Email](mailto:john@johncoates.me)）が開始しました。

バージョン 1.4 以降は [Guillaume Louel](https://github.com/glouel) 氏（[Twitter](https://twitter.com/C_Wiz)）がメンテナンスしています。開発支援を希望する場合は以下から寄付できます。

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/A0A32385Y)

## 動作環境

- macOS Sierra (10.12) 以上、Apple Silicon ネイティブ対応

## コミュニティ

- **このForkで不具合を見つけた場合**: [FAQ](https://aerialscreensaver.github.io/faq.html)、[トラブルシューティング](Documentation/Troubleshooting.md)、[このForkのIssue](../../issues) を確認し、必要なら [このForkにIssueを作成](../../issues/new) してください。
- **upstream起因の不具合の場合**: [JohnCoates/Aerial issues](https://github.com/JohnCoates/Aerial/issues) を利用してください。
- **バグ修正や機能追加をした場合**: [コントリビュートガイド](Documentation/Contribute.ja.md) を参照してください。
- **動画名や説明文の翻訳に参加する場合**: [詳細](Resources/Community/Readme.md) を参照してください。
- **公式コミュニティのサポートを利用したい場合**: upstream の [Community Discord server](https://discord.gg/TPuA5WG) に参加してください。

## 多言語対応

Aerial には、動画内の主な地理情報を重ねて表示する説明機能があります。

![Community Strings example](https://user-images.githubusercontent.com/4295/52958947-75bd6180-3395-11e9-947f-3c77d9f41928.jpg)

動画説明は多言語（スペイン語、フランス語、ポーランド語など）に対応しており、これは多くのボランティアの協力によって実現しています（[対応言語一覧はこちら](Resources/Community/Readme.md)）。技術的な背景がなくても翻訳に参加できるワークフローを整備しています。

参加したい場合は [詳細](Resources/Community/Readme.md) を参照してください。

## ライセンス

このForkは [MIT License](./LICENSE) のもとで公開されています。

MITの条件に基づき、元の著作権表示とライセンス表示を保持しています。詳細は [FORK_NOTICE.ja.md](./FORK_NOTICE.ja.md) を参照してください。
