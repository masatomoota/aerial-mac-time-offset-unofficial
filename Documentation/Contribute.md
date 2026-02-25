# Contributing to Aerial

(If you want to help with translations, please check [this page here](https://github.com/JohnCoates/Aerial/blob/master/Resources/Community/Readme.md).)

This repository is an unofficial fork of [JohnCoates/Aerial](https://github.com/JohnCoates/Aerial).
Use this repository for issues/PRs related to fork-specific behavior (for example, clock time offset changes).
For official upstream changes, please contribute directly to JohnCoates/Aerial.

If you want to contribute code to Aerial, you are more than welcome!

Feel free to directly submit a PR for small changes or quick bug fixes, so we can have a look. 

If you want to implement something more substantial, it might be a good idea to open an issue first to discuss what you want to do, so we can coordinate efforts and help you get around the existing codebase and it's various pitfalls. 

# Warning if you setup your repo prior to 1.7.2

Starting with version 1.7.2, we've removed the cocoapods dependency to Sparkle, and replaced it with a git submodule reference in /Extern). I strongly recomend you pull anew. If you still want to fix your existing repo I would suggest :

```
pod deintegrate
git pull
git submodule update --init --recursive
```

From your main repo folder. 


# How to compile Aerial

This is the easiest way to pull Aerial. 

- From terminal in a suitable location, run `git clone --recurse-submodules <this-fork-repo-url>`. This will bring this fork and its dependencies (Sparkle).  
- In the future, if you wish to update Sparkle, you can run `git submodule update --init --recursive` 
- Open the `Aerial.xcodeproj` in Xcode
- Top left of the screen, pick the "AerialApp" scheme :
![Capture d’écran 2019-06-27 à 12 56 42](https://user-images.githubusercontent.com/37544189/60261086-569e8580-98db-11e9-8fd2-e579786f628d.jpg)
- Build and run. 

The AerialApp scheme compiles Aerial as an App, instead of a screensaver, so you can more easily test and debug your code in Xcode. Use the Aerial scheme to compile as a screensaver. 

If you are running into an issue, open an issue in this fork for fork-specific behavior, or in upstream for official Aerial behavior.
