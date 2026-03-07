//
//  AdvancedViewController.swift
//  Aerial
//
//  Created by Guillaume Louel on 18/07/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Cocoa
import AVFoundation
import VideoToolbox
import ScreenSaver

class AdvancedViewController: NSViewController {
    var windowController: PanelWindowController?
    var firstSetupWindowController: FirstSetupWindowController?

    @IBOutlet var scrollView: NSScrollView!
    
    @IBOutlet var popoverVideoFormat: NSPopover!

    @IBOutlet var popoverH264Indicator: NSButton!
    @IBOutlet var popoverHEVCIndicator: NSButton!
    @IBOutlet var popoverH264Label: NSTextField!
    @IBOutlet var popoverHEVCLabel: NSTextField!

    @IBOutlet var popoverOnBattery: NSPopover!

    @IBOutlet var videoFormatPopup: NSPopUpButton!
    // We need to hide HDR pre-Catalina
    @IBOutlet var menu1080pHDR: NSMenuItem!
    @IBOutlet var menu4KHDR: NSMenuItem!

    @IBOutlet var videoFadesPopup: NSPopUpButton!

    @IBOutlet weak var invertColorsCheckbox: NSButton!

    @IBOutlet var rightArrowSkipCheckbox: NSButton!
    @IBOutlet var muteSoundCheckbox: NSButton!

    @IBOutlet weak var muteAllMacOSSoundsCheckbox: NSButton!
    @IBOutlet var highQualityTextCheckbox: NSButton!

    @IBOutlet var favorOrientationCheckbox: NSButton!
    @IBOutlet var autoplayPreviews: NSButton!

    @IBOutlet var onBatteryPopup: NSPopUpButton!

    @IBOutlet var languagePopup: NSPopUpButton!
    @IBOutlet var languageLabel: NSTextField!

    @IBOutlet var debugCheckbox: NSButton!

    @IBOutlet var showLogButton: NSButton!

    @IBOutlet var launchSetupAgain: NSButton!

    private lazy var importDisplaySettingsButton: NSButton = {
        let button = NSButton(
            title: "Import Display...",
            target: self,
            action: #selector(importDisplaySettingsClick(_:)))
        button.bezelStyle = .rounded
        button.font = .systemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setIcons("square.and.arrow.down")
        return button
    }()

    private lazy var exportDisplaySettingsButton: NSButton = {
        let button = NSButton(
            title: "Export Display...",
            target: self,
            action: #selector(exportDisplaySettingsClick(_:)))
        button.bezelStyle = .rounded
        button.font = .systemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var originalFormat: VideoFormat?
    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.async {
            self.scrollView.contentView.scroll(NSMakePoint(0,0))
        }
        
        // HEVC is available only in macOS 10.13+
        if #available(OSX 10.13, *) {
            videoFormatPopup.selectItem(at: PrefsVideos.videoFormat.rawValue)
        } else {
            // We reset to 1080p below 10.13
            PrefsVideos.videoFormat = VideoFormat.v1080pH264
            videoFormatPopup.selectItem(at: PrefsVideos.videoFormat.rawValue)
            videoFormatPopup.isEnabled = false
        }

        // Save this for future use
        originalFormat = PrefsVideos.videoFormat

        videoFadesPopup.selectItem(at: PrefsVideos.fadeMode.rawValue)

        // We need catalina for HDR ! And we can't use right arrow to skip in Catalina
        if #available(OSX 10.15, *) {
            rightArrowSkipCheckbox.isEnabled = false
        } else {
            menu1080pHDR.isHidden = true
            menu4KHDR.isHidden = true
        }

        if !PrefsVideos.allowSkips {
            rightArrowSkipCheckbox.state = .off
        }

        invertColorsCheckbox.state = PrefsAdvanced.invertColors ? .on : .off
        highQualityTextCheckbox.state = PrefsInfo.highQualityTextRendering ? .on : .off

        muteSoundCheckbox.state = PrefsAdvanced.muteSound ? .on : .off
        muteAllMacOSSoundsCheckbox.state = PrefsAdvanced.muteGlobalSound ? .on : .off
        autoplayPreviews.state = PrefsAdvanced.autoPlayPreviews ? .on : .off
        favorOrientationCheckbox.state = PrefsAdvanced.favorOrientation ? .on : .off

        onBatteryPopup.selectItem(at: PrefsVideos.onBatteryMode.rawValue)

        if PrefsAdvanced.debugMode {
            debugCheckbox.state = .on
        }

        let poisp = PoiStringProvider.sharedInstance
        languagePopup.selectItem(at: poisp.getLanguagePosition())

        // Grab preferred language as proper string
        languageLabel.stringValue = Aerial.helper.getPreferredLanguage()

        showLogButton.setIcons("folder")
        launchSetupAgain.setIcons("aspectratio")
        setupTransferButtons()
        setupPopover()
    }

    private func setupTransferButtons() {
        guard let containerView = showLogButton.superview else {
            return
        }

        containerView.addSubview(exportDisplaySettingsButton)
        containerView.addSubview(importDisplaySettingsButton)
        NSLayoutConstraint.activate([
            importDisplaySettingsButton.trailingAnchor.constraint(equalTo: showLogButton.leadingAnchor, constant: -8),
            exportDisplaySettingsButton.trailingAnchor.constraint(equalTo: importDisplaySettingsButton.leadingAnchor, constant: -8),
            exportDisplaySettingsButton.centerYAnchor.constraint(equalTo: showLogButton.centerYAnchor),
            importDisplaySettingsButton.centerYAnchor.constraint(equalTo: showLogButton.centerYAnchor),
            exportDisplaySettingsButton.widthAnchor.constraint(equalToConstant: 155),
            importDisplaySettingsButton.widthAnchor.constraint(equalToConstant: 155),
            exportDisplaySettingsButton.heightAnchor.constraint(equalTo: showLogButton.heightAnchor),
            importDisplaySettingsButton.heightAnchor.constraint(equalTo: showLogButton.heightAnchor)
        ])
    }

    private func refreshImportedDisplayControls() {
        let poisp = PoiStringProvider.sharedInstance

        invertColorsCheckbox.state = PrefsAdvanced.invertColors ? .on : .off
        highQualityTextCheckbox.state = PrefsInfo.highQualityTextRendering ? .on : .off
        favorOrientationCheckbox.state = PrefsAdvanced.favorOrientation ? .on : .off
        languagePopup.selectItem(at: poisp.getLanguagePosition())
    }

    func setupPopover() {
        // Help popover, GVA detection requires 10.13
        if #available(OSX 10.13, *) {
            if !VTIsHardwareDecodeSupported(kCMVideoCodecType_H264) {
                popoverH264Label.stringValue = "H264 acceleration not supported"
                popoverH264Indicator.image = NSImage(named: NSImage.statusUnavailableName)
            }
            if !VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC) {
                popoverHEVCLabel.stringValue = "HEVC Main10 acceleration not supported"
                popoverHEVCIndicator.image = NSImage(named: NSImage.statusUnavailableName)
            } else {
                let hardwareDetection = HardwareDetection.sharedInstance
                switch hardwareDetection.isHEVCMain10HWDecodingAvailable() {
                case .supported:
                    popoverHEVCLabel.stringValue = "HEVC Main10 acceleration is supported"
                    popoverHEVCIndicator.image = NSImage(named: NSImage.statusAvailableName)
                case .notsupported:
                    popoverHEVCLabel.stringValue = "HEVC Main10 acceleration is not supported"
                    popoverHEVCIndicator.image = NSImage(named: NSImage.statusUnavailableName)
                case .partial:
                    popoverHEVCLabel.stringValue = "HEVC Main10 acceleration is partially supported"
                    popoverHEVCIndicator.image = NSImage(named: NSImage.statusPartiallyAvailableName)
                default:
                    popoverHEVCLabel.stringValue = "HEVC Main10 acceleration status unknown"
                    popoverHEVCIndicator.image = NSImage(named: NSImage.cautionName)
                }
            }
        } else {
            // Fallback on earlier versions
            popoverHEVCIndicator.isHidden = true
            popoverH264Indicator.image = NSImage(named: NSImage.cautionName)
            popoverH264Label.stringValue = "macOS 10.13 or above required"
            popoverHEVCLabel.stringValue = "Hardware acceleration status unknown"
        }
    }

    @IBAction func launchSetupAgainClick(_ sender: NSButton) {
        if firstSetupWindowController == nil {
            let bundle = Bundle(for: PanelWindowController.self)
            // We also load our CustomVideos nib here

            firstSetupWindowController = FirstSetupWindowController()
            var topLevelObjects: NSArray? = NSArray()
            if !bundle.loadNibNamed(NSNib.Name("FirstSetupWindowController"),
                                owner: firstSetupWindowController,
                                topLevelObjects: &topLevelObjects) {
                errorLog("Could not load nib for FirstSetupWindowController, please report")
            }
        }

        DispatchQueue.main.async {
            self.firstSetupWindowController!.windowDidLoad()
            self.firstSetupWindowController!.showWindow(self)
            self.firstSetupWindowController!.window!.makeKeyAndOrderFront(self)
        }
    }

    @IBAction func videoFormatPopupChange(_ sender: NSPopUpButton) {
        let candidateFormat = VideoFormat(rawValue: sender.indexOfSelectedItem)!

        if candidateFormat != originalFormat {
            // swiftlint:disable:next line_length
            if Aerial.helper.showAlert(question: "Changing format will delete all videos", text: "Changing format will delete your downloaded videos. They will be re-downloaded based on your preferences. \n\nYou can also manually redownload videos in Custom Sources.", button1: "Change Format and Delete Videos", button2: "Cancel") {
                PrefsVideos.videoFormat = candidateFormat
                originalFormat = candidateFormat

                Cache.clearCache()
                Cache.clearNonCacheableSources()
                // Sidebar.instance.refreshVideos()
            } else {
                videoFormatPopup.selectItem(at: PrefsVideos.videoFormat.rawValue)
            }
        } else {
            PrefsVideos.videoFormat = candidateFormat
        }
    }

    @IBAction func invertColorsCheckboxClick(_ sender: NSButton) {
        PrefsAdvanced.invertColors = sender.state == .on
    }
    @IBAction func videoFadesPopupChange(_ sender: NSPopUpButton) {
        PrefsVideos.fadeMode = FadeMode(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func highQualityTextClick(_ sender: NSButton) {
        PrefsInfo.highQualityTextRendering = sender.state == .on
    }
    @IBAction func rightArrowSkipClick(_ sender: NSButton) {
        PrefsVideos.allowSkips = sender.state == .on
    }

    @IBAction func muteSoundClick(_ sender: NSButton) {
        PrefsAdvanced.muteSound = sender.state == .on
    }

    @IBAction func muteAllMacOSSoundsClick(_ sender: NSButton) {
        PrefsAdvanced.muteGlobalSound = sender.state == .on
    }
    
    @IBAction func autoPlaysPreviewsClick(_ sender: NSButton) {
        PrefsAdvanced.autoPlayPreviews = sender.state == .on
    }

    @IBAction func favorOrientationClick(_ sender: NSButton) {
        PrefsAdvanced.favorOrientation = sender.state == .on
    }

    @IBAction func onBatteryPopupChange(_ sender: NSPopUpButton) {
        PrefsVideos.onBatteryMode = OnBatteryMode(rawValue: sender.indexOfSelectedItem)!
    }

    @IBAction func languagePopupChange(_ sender: NSPopUpButton) {
        let poisp = PoiStringProvider.sharedInstance
        PrefsAdvanced.ciOverrideLanguage = poisp.getLanguageStringFromPosition(pos: sender.indexOfSelectedItem)
    }

    @IBAction func debugCheckboxClick(_ sender: NSButton) {
        PrefsAdvanced.debugMode = sender.state == .on
    }

    @IBAction func showLogInFinderClick(_ sender: Any) {
        let logfile = Cache.supportPath.appending("/AerialLog.txt")

        // If we don't have a log, just show the folder
        if FileManager.default.fileExists(atPath: logfile) == false {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: Cache.supportPath)
        } else {
            NSWorkspace.shared.selectFile(logfile, inFileViewerRootedAtPath: Cache.supportPath)
        }
    }

    @objc func importDisplaySettingsClick(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["plist"]
        openPanel.title = "Import Aerial Display Settings"
        openPanel.prompt = "Import"
        openPanel.message =
            "Select another Aerial preferences plist. Only display, overlay, brightness, " +
            "language, and time-based presentation settings will be imported."
        openPanel.directoryURL = DisplaySettingsImport.defaultDirectoryURL()

        if let suggestedURL = DisplaySettingsImport.suggestedSourceURL() {
            openPanel.directoryURL = suggestedURL.deletingLastPathComponent()
            openPanel.nameFieldStringValue = suggestedURL.lastPathComponent
        }

        guard openPanel.runModal() == .OK, let sourceURL = openPanel.url else {
            return
        }

        do {
            let result = try DisplaySettingsImport.importDisplaySettings(from: sourceURL)
            refreshImportedDisplayControls()

            Aerial.helper.showInfoAlert(
                title: "Display settings imported",
                text:
                    """
                    Imported \(result.importedKeys.count) settings from \(result.sourceURL.lastPathComponent).

                    If other settings tabs are already open, close and reopen them to refresh the controls.
                    """)
        } catch let error as LocalizedError {
            Aerial.helper.showErrorAlert(
                question: "Couldn't import display settings",
                text: error.errorDescription ?? "An unknown error occurred while importing settings.")
        } catch {
            Aerial.helper.showErrorAlert(
                question: "Couldn't import display settings",
                text: error.localizedDescription)
        }
    }

    @objc func exportDisplaySettingsClick(_ sender: Any) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["plist"]
        savePanel.title = "Export Aerial Display Settings"
        savePanel.nameFieldStringValue = "AerialDisplaySettings.plist"
        savePanel.prompt = "Export"
        savePanel.message =
            "Save the current display-related settings to a plist that can be imported on another Aerial installation."
        savePanel.directoryURL = DisplaySettingsImport.defaultExportDirectoryURL()

        guard savePanel.runModal() == .OK, let destinationURL = savePanel.url else {
            return
        }

        do {
            let result = try DisplaySettingsImport.exportDisplaySettings(to: destinationURL)

            Aerial.helper.showInfoAlert(
                title: "Display settings exported",
                text:
                    """
                    Exported \(result.exportedKeys.count) settings to \(result.destinationURL.lastPathComponent).

                    This file can be imported from the Advanced tab on another Aerial installation.
                    """)
        } catch let error as LocalizedError {
            Aerial.helper.showErrorAlert(
                question: "Couldn't export display settings",
                text: error.errorDescription ?? "An unknown error occurred while exporting settings.")
        } catch {
            Aerial.helper.showErrorAlert(
                question: "Couldn't export display settings",
                text: error.localizedDescription)
        }
    }

    @IBAction func resetAllSettings(_ sender: NSButton) {
        if Aerial.helper.showAlert(
            question: "Reset all settings?",
            text: "This will reset all your settings. After they are reset, Aerial will close System Preferences, you will have to reload it to access settings again.\n\nAre you sure you want to reset your settings?",
            button1: "Reset my settings",
            button2: "Cancel") {

            let process: Process = Process()

            debugLog("clearing old defaults")
            process.launchPath = "/usr/bin/defaults"

            // First remove old ByHost settings
            if #available(OSX 10.15, *) {
                process.arguments = ["-currentHost", "delete", Aerial.helper.getPreferencesDirectory() + "ByHost/com.JohnCoates.Aerial"]
            } else {
                process.arguments = ["-currentHost", "delete", "com.JohnCoates.Aerial"]
            }

            process.launch()
            process.waitUntilExit()

            let process2: Process = Process()

            debugLog("clearing new defaults")
            process2.launchPath = "/usr/bin/defaults"

            // First remove old ByHost settings
            if #available(OSX 10.15, *) {
                process2.arguments = ["delete", Aerial.helper.getPreferencesDirectory() + "com.glouel.Aerial"]
            } else {
                process2.arguments = ["delete", "com.glouel.Aerial"]
            }

            process2.launch()
            process2.waitUntilExit()

            
            
            

            Aerial.helper.showInfoAlert(title: "Settings reset to defaults", text: "Your settings were reset to defaults. \n\nPlease close Aerial and System Preferences in order to reload them.")
        }
    }

    // Helpers, to move in a model when I have a sec

    @IBAction func helpVideoFormat(_ sender: NSButton) {
        popoverVideoFormat.show(relativeTo: sender.preparedContentRect, of: sender, preferredEdge: .maxY)
    }

    @IBAction func helpOnBattery(_ sender: NSButton) {
        popoverOnBattery.show(relativeTo: sender.preparedContentRect, of: sender, preferredEdge: .maxY)
    }

    @IBAction func dolbyVisionClick(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://en.wikipedia.org/wiki/Dolby_Laboratories#Video_processing")!
        workspace.open(url)
    }

    @IBAction func projectPageClick(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://github.com/JohnCoates/Aerial/blob/master/Documentation/HardwareDecoding.md")!
        workspace.open(url)
    }
}

private struct DisplaySettingsImportResult {
    let sourceURL: URL
    let importedKeys: [String]
}

private struct DisplaySettingsExportResult {
    let destinationURL: URL
    let exportedKeys: [String]
}

private enum DisplaySettingsImportError: LocalizedError {
    case unreadableSource(URL)
    case noImportableSettings(URL)
    case missingDestinationPreferences
    case missingSourcePreferences
    case invalidExportData
    case unableToWriteExport(URL)

    var errorDescription: String? {
        switch self {
        case .unreadableSource(let url):
            return "The selected file could not be read as an Aerial preferences plist.\n\nFile: \(url.path)"
        case .noImportableSettings(let url):
            return "The selected plist did not contain any importable display settings.\n\nFile: \(url.path)"
        case .missingDestinationPreferences:
            return "Aerial could not open its current preferences store."
        case .missingSourcePreferences:
            return "Aerial could not read its current display settings."
        case .invalidExportData:
            return "Aerial could not serialize the current display settings for export."
        case .unableToWriteExport(let url):
            return "Aerial could not write the export file.\n\nFile: \(url.path)"
        }
    }
}

private struct DisplaySettingsImport {
    private static let importableKeys: [String] = [
        "newDisplayMode",
        "newViewingMode",
        "aspectMode",
        "displayMarginsAdvanced",
        "horizontalMargin",
        "verticalMargin",
        "advancedMargins",
        "dimBrightness",
        "dimOnlyAtNight",
        "dimOnlyOnBattery",
        "overrideDimInMinutes",
        "startDim",
        "endDim",
        "dimInMinutes",
        "layers",
        "LayerLocation",
        "LayerMessage",
        "LayerClock",
        "LayerDate",
        "LayerBattery",
        "LayerUpdates",
        "LayerWeather",
        "LayerCountdown",
        "LayerTimer",
        "LayerMusic",
        "weatherWindMode",
        "customDateFormat",
        "customTimeFormat",
        "fadeModeText",
        "highQualityTextRendering",
        "overrideMargins",
        "hideUnderCompanion",
        "marginX",
        "marginY",
        "shadowRadius",
        "shadowOpacity",
        "shadowOffsetX",
        "shadowOffsetY",
        "timeMode",
        "manualSunrise",
        "manualSunset",
        "latitude",
        "longitude",
        "solarMode",
        "sunEventWindow",
        "darkModeNightOverride",
        "invertColors",
        "favorOrientation",
        "ciOverrideLanguage",
        "newDisplayDict"
    ]

    private static let legacyModule = "com.JohnCoates.Aerial"
    private static let currentDomain = "com.glouel.Aerial"

    static func defaultDirectoryURL() -> URL {
        if let suggestedSourceURL = suggestedSourceURL() {
            return suggestedSourceURL.deletingLastPathComponent()
        }

        let fm = FileManager.default
        for candidate in commonPreferenceDirectories() where fm.fileExists(atPath: candidate.path) {
            return candidate
        }

        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library", isDirectory: true)
    }

    static func defaultExportDirectoryURL() -> URL {
        let desktopURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop", isDirectory: true)

        if FileManager.default.fileExists(atPath: desktopURL.path) {
            return desktopURL
        }

        return FileManager.default.homeDirectoryForCurrentUser
    }

    static func suggestedSourceURL() -> URL? {
        availableSourceURLs().max { lhs, rhs in
            modificationDate(for: lhs) < modificationDate(for: rhs)
        }
    }

    static func importDisplaySettings(from sourceURL: URL) throws -> DisplaySettingsImportResult {
        guard let sourcePreferences = NSDictionary(contentsOf: sourceURL) as? [String: Any] else {
            throw DisplaySettingsImportError.unreadableSource(sourceURL)
        }

        let importableEntries = importableKeys.compactMap { key in
            sourcePreferences[key].map { (key, $0) }
        }

        guard !importableEntries.isEmpty else {
            throw DisplaySettingsImportError.noImportableSettings(sourceURL)
        }

        try write(entries: importableEntries)

        PrefsInfo.updateLayerList()
        DisplayDetection.sharedInstance.detectDisplays()

        return DisplaySettingsImportResult(
            sourceURL: sourceURL,
            importedKeys: importableEntries.map { $0.0 })
    }

    static func exportDisplaySettings(to destinationURL: URL) throws -> DisplaySettingsExportResult {
        let exportEntries = try currentEntries()

        guard !exportEntries.isEmpty else {
            throw DisplaySettingsImportError.missingSourcePreferences
        }

        var exportDictionary = [String: Any]()
        for (key, value) in exportEntries {
            exportDictionary[key] = value
        }

        exportDictionary["_AerialDisplaySettingsExport"] = true
        exportDictionary["_AerialDisplaySettingsVersion"] = 1

        guard PropertyListSerialization.propertyList(exportDictionary, isValidFor: .xml) else {
            throw DisplaySettingsImportError.invalidExportData
        }

        let data = try PropertyListSerialization.data(
            fromPropertyList: exportDictionary,
            format: .xml,
            options: 0)

        do {
            try data.write(to: destinationURL, options: .atomic)
        } catch {
            throw DisplaySettingsImportError.unableToWriteExport(destinationURL)
        }

        return DisplaySettingsExportResult(
            destinationURL: destinationURL,
            exportedKeys: exportEntries.map { $0.0 })
    }

    private static func availableSourceURLs() -> [URL] {
        let fm = FileManager.default
        let currentURL = activePreferencesURL().standardizedFileURL

        var urls = exactPreferenceFiles().filter { fm.fileExists(atPath: $0.path) }

        for directory in byHostDirectories() where fm.fileExists(atPath: directory.path) {
            if let children = try? fm.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]) {
                urls.append(contentsOf: children.filter {
                    $0.pathExtension == "plist" &&
                    ($0.lastPathComponent.hasPrefix(legacyModule) || $0.lastPathComponent.hasPrefix(currentDomain))
                })
            }
        }

        let uniqueURLs = Array(Set(urls.map { $0.standardizedFileURL }))
        return uniqueURLs.filter { $0 != currentURL }
    }

    private static func exactPreferenceFiles() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let normalPrefs = home.appendingPathComponent("Library/Preferences", isDirectory: true)
        let containerPrefs = home
            .appendingPathComponent("Library/Containers", isDirectory: true)
            .appendingPathComponent("com.apple.ScreenSaver.Engine.legacyScreenSaver", isDirectory: true)
            .appendingPathComponent("Data/Library/Preferences", isDirectory: true)

        return [
            normalPrefs.appendingPathComponent("\(currentDomain).plist"),
            normalPrefs.appendingPathComponent("\(legacyModule).plist"),
            containerPrefs.appendingPathComponent("\(currentDomain).plist"),
            containerPrefs.appendingPathComponent("\(legacyModule).plist")
        ]
    }

    private static func commonPreferenceDirectories() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let normalPrefs = home.appendingPathComponent("Library/Preferences", isDirectory: true)
        let containerPrefs = home
            .appendingPathComponent("Library/Containers", isDirectory: true)
            .appendingPathComponent("com.apple.ScreenSaver.Engine.legacyScreenSaver", isDirectory: true)
            .appendingPathComponent("Data/Library/Preferences", isDirectory: true)

        return [
            normalPrefs,
            normalPrefs.appendingPathComponent("ByHost", isDirectory: true),
            containerPrefs,
            containerPrefs.appendingPathComponent("ByHost", isDirectory: true)
        ]
    }

    private static func byHostDirectories() -> [URL] {
        commonPreferenceDirectories().filter { $0.lastPathComponent == "ByHost" }
    }

    private static func activePreferencesURL() -> URL {
        URL(fileURLWithPath: Aerial.helper.getPreferencesDirectory(), isDirectory: true)
            .appendingPathComponent("\(currentDomain).plist")
    }

    private static func currentEntries() throws -> [(String, Any)] {
        let preferences: [String: Any]

        if #available(OSX 10.15, *) {
            guard let defaults = UserDefaults(suiteName: Aerial.helper.getPreferencesDirectory() + currentDomain) else {
                throw DisplaySettingsImportError.missingSourcePreferences
            }

            preferences = defaults.dictionaryRepresentation()
        } else {
            guard let defaults = ScreenSaverDefaults(forModuleWithName: legacyModule) else {
                throw DisplaySettingsImportError.missingSourcePreferences
            }

            preferences = defaults.dictionaryRepresentation()
        }

        return importableKeys.compactMap { key in
            preferences[key].map { (key, $0) }
        }
    }

    private static func modificationDate(for url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }

    private static func write(entries: [(String, Any)]) throws {
        if #available(OSX 10.15, *) {
            guard let defaults = UserDefaults(suiteName: Aerial.helper.getPreferencesDirectory() + currentDomain) else {
                throw DisplaySettingsImportError.missingDestinationPreferences
            }

            for (key, value) in entries {
                defaults.set(value, forKey: key)
            }

            defaults.synchronize()
        } else {
            guard let defaults = ScreenSaverDefaults(forModuleWithName: legacyModule) else {
                throw DisplaySettingsImportError.missingDestinationPreferences
            }

            for (key, value) in entries {
                defaults.set(value, forKey: key)
            }

            defaults.synchronize()
        }
    }
}
