# Aerial へのコントリビュート

[English](./Contribute.md)

（翻訳に協力したい場合は [こちらのページ](https://github.com/JohnCoates/Aerial/blob/master/Resources/Community/Readme.md) を参照してください。）

このリポジトリは [JohnCoates/Aerial](https://github.com/JohnCoates/Aerial) の非公式フォークです。  
このFork固有の挙動（例: 時計オフセット機能）に関する Issue / PR はこのリポジトリを使ってください。  
公式upstreamへの変更は JohnCoates/Aerial に直接コントリビュートしてください。

Aerial へのコード貢献は歓迎しています。

小さな変更や軽微なバグ修正は、直接 PR を送ってください。

大きな機能追加を行う場合は、先に Issue で相談することを推奨します。既存コードの構造や注意点を共有しやすくなります。

# 1.7.2 より前に環境を作った場合の注意

1.7.2 以降、Sparkle 依存は CocoaPods ではなく `/Extern` の git submodule 参照へ変更されています。古い環境を引き継ぐより、再取得を推奨します。既存環境を直す場合は次を実行してください。

```
pod deintegrate
git pull
git submodule update --init --recursive
```

（リポジトリのルートで実行）

# Aerial のビルド方法

最も簡単な取得方法です。

- ターミナルで適切な場所に移動し、`git clone --recurse-submodules <this-fork-repo-url>` を実行します。Fork本体と依存（Sparkle）を取得できます。  
- 今後 Sparkle を更新する場合は `git submodule update --init --recursive` を実行します。  
- Xcode で `Aerial.xcodeproj` を開きます。  
- 画面左上で `AerialApp` スキームを選択します。  
![Capture d’écran 2019-06-27 à 12 56 42](https://user-images.githubusercontent.com/37544189/60261086-569e8580-98db-11e9-8fd2-e579786f628d.jpg)
- Build & Run します。

`AerialApp` スキームはスクリーンセーバーではなくアプリとしてビルドされるため、Xcode でのデバッグが容易です。スクリーンセーバーとしてビルドする場合は `Aerial` スキームを使用してください。

問題が発生した場合は、Fork固有の内容はこのForkへ、公式Aerialの内容はupstreamへIssueを作成してください。
