import Foundation

/// Sparkle update framework integration for GroktoDash.
///
/// To enable automatic updates:
/// 1. Add Sparkle (https://sparkle-project.org) via SPM:
///    Package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0")
/// 2. Uncomment the framework import and update check calls below.
///
/// Sparkle is MIT-licensed and is the standard update framework for
/// indie macOS apps.  It handles appcast feeds, delta updates, and
/// in-app update UI.  No account system, no analytics.

// import Sparkle

struct Updater {
    /// URL of the appcast feed (GitHub Releases JSON transformed to Sparkle format).
    /// GitHub Actions generates this during the release workflow.
    static let appcastURL = URL(string: "https://github.com/groktopus/groktodash/releases/download/appcast.xml")!

    /// Check for updates (called on app launch and periodically).
    /// Uncomment when Sparkle is added as a dependency.
    static func checkForUpdates() {
        // let updater = SPUStandardUpdaterController(
        //     startingUpdater: true,
        //     updaterDelegate: nil,
        //     userDriverDelegate: nil
        // )
        // updater.updater.checkForUpdatesInBackground()
        print("[Sparkle] Update check not yet wired — add Sparkle SPM dependency to enable.")
    }
}
