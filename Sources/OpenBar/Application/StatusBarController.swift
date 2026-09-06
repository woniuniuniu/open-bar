import AppKit
import Foundation

@MainActor
final class StatusBarController: NSObject {
    static let toggleID = "status:com.woniuniuniu.OpenBar::OpenBar.Toggle"

    private enum AutosaveName {
        // A fresh name prevents a stale position from an earlier experimental
        // build from placing the native item in MenuBarAgent's hidden slot.
        static let toggle = "OpenBar.NativeToggle.v3"
        static let boundary = "OpenBar.NativeBoundary.v2"
    }

    let legacySections: LegacySectionController?

    private let boundaryItem: NSStatusItem?
    private var statusItem: NSStatusItem
    private let model: AppModel
    private let onOpen: () -> Void
    private let onQuit: () -> Void
    private var panelController: StatusBarPanelController!
    private var visibleFallback: NSPanel?
    private var expanded = false
    private var panelVisible = false

    init(model: AppModel, onOpen: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.model = model
        self.onOpen = onOpen
        self.onQuit = onQuit
        legacySections = ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 27
            ? LegacySectionController() : nil
        boundaryItem = ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 27
            ? NSStatusBar.system.statusItem(withLength: 0)
            : nil
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        boundaryItem?.autosaveName = AutosaveName.boundary
        statusItem.autosaveName = AutosaveName.toggle
        panelController = StatusBarPanelController(model: model) { [weak self] visible in
            self?.panelVisible = visible
            self?.updateIcon()
        }
        // Keep the boundary as a normal zero-width status item on every
        // supported macOS version. MenuBarAgent composes status items as a
        // single native row; removing the companion item during startup can
        // leave the next item in an off-screen AX slot (x=-1).
        configureBoundary()
        configureItem()
        installVisibilityFallbackIfNeeded()
    }

    var toggleMenuBarItem: LiveMenuBarItem? {
        let frame = statusItemFrame() ?? estimatedStatusItemFrame
        return LiveMenuBarItem(
            id: Self.toggleID,
            windowID: 0,
            hostPID: ProcessInfo.processInfo.processIdentifier,
            hostBundleIdentifier: Bundle.main.bundleIdentifier ?? "com.woniuniuniu.OpenBar",
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "com.woniuniuniu.OpenBar",
            semanticIdentifier: "status:com.woniuniuniu.OpenBar::OpenBar.Toggle",
            rawTitle: "OpenBar.Toggle",
            displayName: L("Open Bar Brand"),
            symbolName: "arrow.down",
            frame: frame,
            isProtected: true,
            actualSection: nil
        )
    }

    func update(expanded: Bool) {
        self.expanded = expanded
        updateIcon()
        // OPEN BAR's own control is the escape hatch for every other section.
        // It must remain visible even when a user moves its record in the
        // workspace; visibility policies apply to managed third-party items.
        statusItem.isVisible = true
        boundaryItem?.length = 0
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27 {
            // Keep the hidden boundary as a one-pixel, mouse-transparent
            // anchor. Leaving AppKit's default boundary window untouched can
            // make MenuBarAgent place the adjacent native item at AX x=-1.
            statusItem.button?.contentTintColor = nil
            statusItem.button?.toolTip = expanded ? L("Close Quick Bar") : L("Open Quick Bar")
        }
        legacySections?.setExpanded(expanded)
    }

    func hideQuickBar() { panelController.hide() }

    /// MenuBarAgent can rebuild the native row after an assessment assertion
    /// is activated. Reassert visibility after that rebuild so the ordinary
    /// OPEN BAR status item is not left in the off-screen overflow slot.
    func reassertNativeItem() {
        update(expanded: model.isExpanded)
        Diagnostics.shared.append("native status item asserted; frame=\(statusItemFrame() ?? .zero)")
    }

    /// MenuBarAgent can retain the first NSStatusItem in its pre-assessment
    /// slot. Recreating only this one item after the assertion is active makes
    /// AppKit register it through the normal visible-status-item path.
    func rebuildNativeItem() {
        NSStatusBar.system.removeStatusItem(statusItem)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.autosaveName = AutosaveName.toggle
        configureItem()
        update(expanded: model.isExpanded)
        Diagnostics.shared.append("native status item rebuilt; frame=\(statusItemFrame() ?? .zero)")
    }

    func stop() {
        panelController.hide()
        visibleFallback?.orderOut(nil)
        visibleFallback = nil
        if let boundaryItem { NSStatusBar.system.removeStatusItem(boundaryItem) }
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func configureItem() {
        guard let button = statusItem.button else { return }
        button.imagePosition = .imageLeading
        button.imageHugsTitle = true
        button.title = "若栏"
        button.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        button.appearsDisabled = false
        button.alphaValue = 1
        button.target = self
        button.action = #selector(clicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = L("Open Quick Bar")
        button.setAccessibilityIdentifier("OpenBar.Toggle")
        button.setAccessibilityLabel(L("Open Bar Brand"))
        updateIcon()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            Diagnostics.shared.append(
                "native status item; visible=\(self.statusItem.isVisible); length=\(self.statusItem.length); bounds=\(self.statusItem.button?.bounds ?? .zero)"
            )
        }
    }

    /// Tahoe can expose an NSStatusItem through AX while failing to paint it
    /// in the menu bar after an assessment change. Keep a transparent,
    /// menu-bar-level button as a visual fallback so the product always has a
    /// real clickable control in the top bar.
    private func installVisibilityFallbackIfNeeded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, self.visibleFallback == nil else { return }
            guard let screen = NSScreen.main else { return }
            let frame = self.statusItem.button?.window?.frame ?? .zero
            let menuBarTop = screen.frame.maxY
            let nativeVisible = frame.width > 0 && frame.height > 0 && frame.minY >= menuBarTop - 40
            guard !nativeVisible else { return }

            let panel = NSPanel(
                contentRect: NSRect(x: screen.frame.maxX - 220, y: menuBarTop - 28, width: 68, height: 24),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.level = .statusBar
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.hidesOnDeactivate = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            let button = NSButton(frame: panel.contentView?.bounds ?? .zero)
            button.autoresizingMask = [.width, .height]
            button.isBordered = false
            button.bezelStyle = .texturedRounded
            button.title = "若栏 􀆾"
            button.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            button.contentTintColor = .labelColor
            button.target = self
            button.action = #selector(self.fallbackClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            panel.contentView = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
            panel.contentView?.addSubview(button)
            panel.orderFrontRegardless()
            self.visibleFallback = panel
            Diagnostics.shared.append("installed visible menu bar fallback; frame=\(panel.frame)")
        }
    }

    @objc private func fallbackClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp { showMenu() }
        else if panelVisible { panelController.hide() }
        else { panelController.show(anchor: visibleFallback?.frame ?? estimatedStatusItemFrame) }
    }

    private func configureBoundary() {
        guard let boundaryItem, let button = boundaryItem.button else { return }
        boundaryItem.length = 0
        button.image = nil
        button.isEnabled = false
        button.alphaValue = 0
        button.setAccessibilityIdentifier("OpenBar.HiddenBoundary")
    }

    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp { showMenu() }
        else if panelVisible { panelController.hide() }
        else {
            panelController.show(anchor: statusItemFrame())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                self?.model.refresh(reconcile: false)
            }
        }
    }

    private func showMenu() {
        panelController.hide()
        let menu = NSMenu(title: "OPEN BAR")
        addItem(to: menu, title: expanded ? L("Collapse Hidden Items") : L("Expand Hidden Items"),
                symbol: expanded ? "eye.slash" : "eye", action: #selector(toggleExpanded))
        menu.addItem(.separator())
        addItem(to: menu, title: L("AI One-click Placement"), symbol: "sparkles", action: #selector(prepareAIPlacement))
        addItem(to: menu, title: L("Open OPEN BAR"), symbol: "slider.horizontal.3", action: #selector(open))
        addItem(to: menu, title: L("Scan Now"), symbol: "arrow.clockwise", action: #selector(refresh))
        menu.addItem(.separator())
        addItem(to: menu, title: L("Quit OPEN BAR"), symbol: "power", action: #selector(quit))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func addItem(to menu: NSMenu, title: String, symbol: String, action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        menu.addItem(item)
    }

    private func updateIcon() {
        let configuration = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        statusItem.button?.image = NSImage(
            systemSymbolName: "chevron.down",
            accessibilityDescription: L("Open Quick Bar")
        )?.withSymbolConfiguration(configuration)
        statusItem.button?.image?.isTemplate = true
        statusItem.button?.toolTip = panelVisible ? L("Close Quick Bar") : L("Open Quick Bar")
    }

    private func statusItemFrame() -> CGRect? {
        guard let button = statusItem.button else { return nil }
        let frame = button.accessibilityFrame()
        guard frame.width > 0, frame.height > 0 else { return nil }
        return frame
    }

    private var estimatedStatusItemFrame: CGRect {
        let screen = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        return CGRect(x: screen.maxX - 220, y: screen.maxY - 24, width: 24, height: 24)
    }

    @objc private func toggleExpanded() { model.toggleExpanded() }
    @objc private func prepareAIPlacement() { model.prepareAIPlacement() }
    @objc private func open() { onOpen() }
    @objc private func refresh() { model.refresh(reconcile: false) }
    @objc private func quit() { onQuit() }
}
