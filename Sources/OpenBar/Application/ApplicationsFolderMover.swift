import AppKit
import Foundation

/// On macOS 27, MenuBarAgent can only attribute status items to apps that
/// live in /Applications. Hiding items from any other location would also
/// hide OPEN BAR's own control, so offer to move the app there once.
@MainActor
enum ApplicationsFolderMover {
    static func offerMoveIfNeeded() {
        guard ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27,
              !MenuBarAgentBackend.isInstalledInApplicationsFolder
        else { return }

        let alert = NSAlert()
        alert.messageText = L("Move OPEN BAR to the Applications folder?")
        alert.informativeText = L("On macOS 27, OPEN BAR can hide menu bar items only when it runs from the Applications folder.")
        alert.addButton(withTitle: L("Move to Applications"))
        alert.addButton(withTitle: L("Not Now"))
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let fileManager = FileManager.default
        let source = Bundle.main.bundleURL
        let destination = URL(fileURLWithPath: "/Applications", isDirectory: true)
            .appendingPathComponent(source.lastPathComponent)
        do {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.trashItem(at: destination, resultingItemURL: nil)
            }
            try fileManager.copyItem(at: source, to: destination)
        } catch {
            Diagnostics.shared.append("move to /Applications failed: \(error.localizedDescription)")
            let failure = NSAlert()
            failure.messageText = L("Couldn't move OPEN BAR")
            failure.informativeText = LF(
                "Drag OPEN BAR into the Applications folder in Finder, then open it again. (%@)",
                error.localizedDescription
            )
            failure.runModal()
            return
        }

        // A second copy elsewhere keeps a duplicate LaunchServices record for
        // the same bundle identifier. Remove it when the location allows.
        try? fileManager.trashItem(at: source, resultingItemURL: nil)
        Diagnostics.shared.append("moved to \(destination.path); relaunching")

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: destination, configuration: configuration) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }
}
