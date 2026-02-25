# このForkをGitHubで公開する手順

[English](./ForkPublish.md)

このリポジトリは次の upstream の非公式フォークとして公開する前提で整備されています。
- https://github.com/JohnCoates/Aerial

## 現在の公開名

- 表示名: `Aerial for Mac Time Offset (Unofficial)`
- GitHub リポジトリスラッグ: `aerial-mac-time-offset-unofficial`

## 1) GitHub CLI に認証する

```bash
gh auth login
```

## 2) GitHub 上で Fork を作成する

```bash
gh repo fork JohnCoates/Aerial --clone=false
```

Fork はアカウント配下に作成されます（1つのupstreamに対して直接Forkは1つ）。

## 3) ローカルリポジトリの remote を設定する

このローカルリポジトリでは `upstream` が `JohnCoates/Aerial` です。  
自分のForkを `origin` として追加します。

```bash
git remote add origin https://github.com/<your-account>/aerial-mac-time-offset-unofficial.git
git remote -v
```

## 4) 変更を push する

```bash
git add Aerial/Source/Views/Layers/ClockLayer.swift Readme.md issue_template.md Documentation/Contribute.md Documentation/ForkPublish.md FORK_NOTICE.md
git commit -m "Add clock offset customization docs and fork attribution"
git push -u origin master
```

## 5) 任意: リポジトリスラッグをリネームする

表示名に合わせて URL スラッグを変更したい場合:

```bash
gh repo rename aerial-mac-time-offset-unofficial --repo <your-account>/<current-fork-name>
git remote set-url origin https://github.com/<your-account>/aerial-mac-time-offset-unofficial.git
```

## 6) 推奨リポジトリ説明文

GitHub の Settings で次を設定:

`Unofficial fork of JohnCoates/Aerial with manual time-offset support for clock overlay.`

## このリポジトリの現状

- GitHub URL: `https://github.com/masatomoota/aerial-mac-time-offset-unofficial`
- `origin`: `https://github.com/masatomoota/aerial-mac-time-offset-unofficial.git`
- `upstream`: `https://github.com/JohnCoates/Aerial.git`
