<p align="center">
  <img src="https://cloud.githubusercontent.com/assets/499192/10754100/c0e1cc4c-7c95-11e5-9d3b-842d3acc2fd5.gif">
</p>

# Aerial for Mac Time Offset (Unofficial)

> This repository is an unofficial fork of [JohnCoates/Aerial](https://github.com/JohnCoates/Aerial).  
> It adds support for applying a manual offset to the on-screen clock display.  
> It is not affiliated with, endorsed by, or supported by the official Aerial maintainers.

Aerial is a Mac screensaver (macOS 10.12 or later) based on the new Apple TV screensaver that displays the Aerial movies Apple shot over New York, San Francisco, Hawaii, China, etc. Starting with version 2.0.0, it also includes videos shared by Joshua Michaels & Hal Bergman!

Aerial is completely open source, so feel free to contribute to its development.

This repository is used **solely** for development.

## Fork-specific feature: manual clock offset

- Environment variable: `AERIAL_CLOCK_OFFSET_MINUTES`
- Example: `AERIAL_CLOCK_OFFSET_MINUTES=-540`
- Behavior when unset or invalid: defaults to `10` minutes (same behavior as this fork's current default)

Starting with version 2.3.0, Aerial can now display current weather information *and* forecasts to your location, thanks to [OpenWeather](https://openweathermap.org). 

![openweather_logo](https://user-images.githubusercontent.com/37544189/115738975-d689bf80-a38d-11eb-809b-fbb019e6ed08.png)

We thank [OpenWeather](https://openweathermap.org) for their support of Open Source projects. 

# Official project

- Official upstream repository: [JohnCoates/Aerial](https://github.com/JohnCoates/Aerial)
- Official project website: [aerialscreensaver.github.io](https://aerialscreensaver.github.io)
- Windows fork: [OrangeJedi/Aerial](https://github.com/OrangeJedi/Aerial)  
- Linux implementation: [graysky2/xscreensaver-aerial](https://github.com/graysky2/xscreensaver-aerial/)

## About Aerial 

Aerial was started in 2015 by John Coates ([Twitter](https://twitter.com/JohnCoatesDev), [Email](mailto:john@johncoates.me))

Starting with version 1.4, Aerial is maintained by [Guillaume Louel](https://github.com/glouel) ([Twitter](https://twitter.com/C_Wiz)). If you are looking to support the development of Aerial, feel free to donate using the following button :

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/A0A32385Y)


## Compatibility

- macOS Sierra (10.12) and above, natively compiled for Apple Silicon

## Community

- **Found a bug in this fork?** Check [FAQ](https://aerialscreensaver.github.io/faq.html), the [troubleshooting page](Documentation/Troubleshooting.md), and [this fork's issues](../../issues). Then [open an issue in this fork](../../issues/new).
- **Found an upstream bug?** Please use [JohnCoates/Aerial issues](https://github.com/JohnCoates/Aerial/issues).
- **Have you fixed a bug or added a feature?** See [contributing guide](Documentation/Contribute.md).
- **Can you translate videos names and descriptions?** [Read details](Resources/Community/Readme.md).
- **Want official community support?** Join the upstream [Community Discord server](https://discord.gg/TPuA5WG).

## Multilingual Support

Aerial features overlay descriptions of the main geographical features displayed in the videos.

![Community Strings example](https://user-images.githubusercontent.com/4295/52958947-75bd6180-3395-11e9-947f-3c77d9f41928.jpg)

Video descriptions are available in many languages (Spanish, French, Polish… [check the complete list here](Resources/Community/Readme.md)) and that is only possible thanks to the collaboration and interested work of many volunteers. To best serve the international community we've defined a translation workflow that allows any person, even with **no technical background** to help translate the descriptions.

If you want to collaborate, please [read the details here](Resources/Community/Readme.md).

## License

This fork remains under the [MIT License](./LICENSE).

Per MIT terms, original copyright and license notices are retained.
See [FORK_NOTICE.md](./FORK_NOTICE.md) for attribution and fork policy.
