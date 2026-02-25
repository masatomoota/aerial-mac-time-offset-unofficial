# Publish This Fork on GitHub

This repository is prepared to be published as an unofficial fork of:
- https://github.com/JohnCoates/Aerial

## Recommended public title

- Display title: `Aerial for Mac Time Offset (Unofficial)`
- GitHub repository slug (no spaces): `aerial-mac-time-offset-unofficial`

## 1) Authenticate GitHub CLI

```bash
gh auth login
```

## 2) Create your fork on GitHub

```bash
gh repo fork JohnCoates/Aerial --clone=false
```

This creates `masatomo/Aerial` as a GitHub fork.

## 3) Configure remotes in this local repo

This local repo already uses `upstream` for `JohnCoates/Aerial`.
Add your fork as `origin`:

```bash
git remote add origin https://github.com/masatomo/Aerial.git
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
gh repo rename aerial-mac-time-offset-unofficial --repo masatomo/Aerial
git remote set-url origin https://github.com/masatomo/aerial-mac-time-offset-unofficial.git
```

## 6) Recommended repository description

Set in GitHub repository settings:

`Unofficial fork of JohnCoates/Aerial with manual time-offset support for clock overlay.`
