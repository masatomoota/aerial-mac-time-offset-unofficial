# Publish This Fork on GitHub

This repository is prepared to be published as an unofficial fork of:
- https://github.com/JohnCoates/Aerial

## Current public title

- Display title: `Aerial for Mac Time Offset (Unofficial)`
- GitHub repository slug: `aerial-mac-time-offset-unofficial`

## 1) Authenticate GitHub CLI

```bash
gh auth login
```

## 2) Create your fork on GitHub

```bash
gh repo fork JohnCoates/Aerial --clone=false
```

This creates a fork in your account (only one direct fork per upstream repository).

## 3) Configure remotes in this local repo

This local repo already uses `upstream` for `JohnCoates/Aerial`.
Add your fork as `origin`:

```bash
git remote add origin https://github.com/<your-account>/aerial-mac-time-offset-unofficial.git
git remote -v
```

## 4) Push your changes

```bash
git add Aerial/Source/Views/Layers/ClockLayer.swift Readme.md issue_template.md Documentation/Contribute.md Documentation/ForkPublish.md FORK_NOTICE.md
git commit -m "Add clock offset customization docs and fork attribution"
git push -u origin master
```

## 5) Optional: rename repository slug

If you want the URL slug to match the display title:

```bash
gh repo rename aerial-mac-time-offset-unofficial --repo <your-account>/<current-fork-name>
git remote set-url origin https://github.com/<your-account>/aerial-mac-time-offset-unofficial.git
```

## 6) Recommended repository description

Set in GitHub repository settings:

`Unofficial fork of JohnCoates/Aerial with manual time-offset support for clock overlay.`

## This repository's current state

- GitHub URL: `https://github.com/masatomoota/aerial-mac-time-offset-unofficial`
- `origin`: `https://github.com/masatomoota/aerial-mac-time-offset-unofficial.git`
- `upstream`: `https://github.com/JohnCoates/Aerial.git`
