//
//  MATabBarItem.swift
//  MATabView
//
//  Created by Ashwin Paudel on 2022-01-06.
//  Copyright © 2021-2022 Ashwin Paudel. All rights reserved.
//
// Some code used from: https://github.com/robin/LYTabView/blob/develop/LYTabView/LYTabItemView.swift

import Cocoa

@objc public protocol MATabBarItemDelegate: NSObjectProtocol {
    @objc optional func tabBarItem(_ tabBarItem: MATabBarItem, wantsToClose tab: MATab)
    @objc optional func tabBarItem(_ tabBarItem: MATabBarItem, wantsToHide tab: MATab)
}

open class MATabBarItem: NSButton, NSDraggingSource, NSPasteboardItemDataProvider {
    open var tabBar: MATabBar?
    open var tab: MATab
    var isSelectedTab = false
    open weak var delegate: MATabBarItemDelegate?
    open var configuration = MATabViewConfiguration()

    let tabTitle = NSTextField(frame: .zero)
    open var closeButton = NSButton(frame: .zero)

    var xPosition: CGFloat = 4
    var yPosition: CGFloat = 2
    var closeButtonSize = NSSize(width: 16, height: 16)

    private var dragOffset: CGFloat?
    private var isDragging = false
    private var draggingView: NSImageView?
    private var draggingViewLeadingConstraint: NSLayoutConstraint?

    /// The Tab Title
    open var label: String {
        get {
            return tabTitle.stringValue
        }
        set(title) {
            tabTitle.stringValue = title as String
        }
    }

    // MARK: - Initilizers

    public required init(frame frameRect: NSRect, tab: MATab) {
        self.tab = tab
        isSelectedTab = tab.isSelectedTab
        super.init(frame: frameRect)
        configureViews()

        let menu = NSMenu()
        menu.addItem(withTitle: "Hide Tab", action: #selector(hideTab), keyEquivalent: "")
        self.menu = menu
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        var bgColor: NSColor = configuration.lightTabColor
        layer?.borderColor = configuration.lightTabBorderColor.cgColor
        layer?.cornerRadius = 4
        layer?.borderWidth = 1
        tabTitle.textColor = configuration.lightTabTitleTextColor
        let appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"

        if appearance == "Dark" {
            bgColor = configuration.darkTabColor
            layer?.borderColor = configuration.darkTabBorderColor.cgColor
            tabTitle.textColor = configuration.darkTabTitleTextColor
        }

        layer?.masksToBounds = true
        layer?.backgroundColor = bgColor.cgColor
        bgColor.setFill()
        dirtyRect.fill()
    }

    // MARK: - Functions

    open func updateColors(configuration: MATabViewConfiguration) {
        wantsLayer = true
        self.configuration = configuration
        var bgColor: NSColor = configuration.lightTabColor
        layer?.borderColor = configuration.lightTabBorderColor.cgColor
        tabTitle.textColor = configuration.lightTabTitleTextColor
        let appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"

        if appearance == "Dark" {
            bgColor = configuration.darkTabColor
            layer?.borderColor = configuration.darkTabBorderColor.cgColor
            tabTitle.textColor = configuration.darkTabTitleTextColor
        }

        layer?.backgroundColor = bgColor.cgColor
        (cell as? NSButtonCell)?.backgroundColor = bgColor
    }

    private final func configureViews() {
        // Tab Title
        let position = xPosition * 2 + closeButtonSize.width

        tabTitle.translatesAutoresizingMaskIntoConstraints = false
        tabTitle.isEditable = false
        tabTitle.alignment = .center
        tabTitle.isBordered = false
        tabTitle.drawsBackground = false
        addSubview(tabTitle)
        tabTitle.trailingAnchor
            .constraint(greaterThanOrEqualTo: trailingAnchor, constant: -position).isActive = true
        tabTitle.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: position).isActive = true
        tabTitle.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        tabTitle.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        tabTitle.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: yPosition).isActive = true
        tabTitle.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -yPosition).isActive = true
        tabTitle.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: NSLayoutConstraint.Priority.defaultLow.rawValue - 10), for: .horizontal)
        tabTitle.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.defaultLow, for: .horizontal)
        tabTitle.lineBreakMode = .byTruncatingTail

        // Close button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.target = self
        closeButton.action = #selector(closeTab)
        closeButton.heightAnchor.constraint(equalToConstant: closeButtonSize.height).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: closeButtonSize.width).isActive = true
        addSubview(closeButton)
        closeButton.trailingAnchor
            .constraint(greaterThanOrEqualTo: tabTitle.leadingAnchor, constant: -xPosition).isActive = true
        closeButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: yPosition).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: xPosition).isActive = true
        closeButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        closeButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -yPosition).isActive = true
        closeButton.bezelStyle = .shadowlessSquare
        closeButton.isBordered = false
        closeButton.imagePosition = .imageOnly
        closeButton.layer?.masksToBounds = false
        closeButton.wantsLayer = true

        tabTitle.stringValue = tab.title
        let area = NSTrackingArea(rect: bounds, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect, .enabledDuringMouseDrag], owner: self, userInfo: nil)
        addTrackingArea(area)

        closeButton.image = tab.icon
    }

    override open func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        closeButton.contentTintColor = configuration.darkTabTitleTextColor
        closeButton.animator().image = NSImage(named: NSImage.stopProgressTemplateName)
        animator().alphaValue = 0.8
    }

    override open func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        closeButton.animator().image = tab.icon
        animator().alphaValue = isSelectedTab ? 1 : 0.6
    }

//    override open func mouseDown(with event: NSEvent) {
//        if !isDragging {
//            createDragAndDropSource(with: event)
//        }
//    }

    // MARK: - Button Actions

    @objc func closeTab() {
        delegate?.tabBarItem?(self, wantsToClose: tab)
    }

    @objc func hideTab() {
        delegate?.tabBarItem?(self, wantsToHide: tab)
    }

    // MARK: - Dragging Source

    override open func mouseDragged(with event: NSEvent) {
        if !isDragging {
            createDragAndDropSource(with: event)
        }
    }

    func createDragAndDropSource(with event: NSEvent) {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setData("testing".data(using: .utf8)!, forType: .string)
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        var draggingRect = frame
        draggingRect.size.width = 1
        draggingRect.size.height = 1
        let testImage = NSImage(size: .init(width: 1, height: 1))

        draggingItem.setDraggingFrame(draggingRect, contents: testImage)
        let draggingSession = beginDraggingSession(with: [draggingItem], event: event, source: self)
        draggingSession.animatesToStartingPositionsOnCancelOrFail = true
    }

    public func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {}

    public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        if context == .withinApplication {
            return .move
        }
        return NSDragOperation()
    }

    public func ignoreModifierKeys(for session: NSDraggingSession) -> Bool {
        return true
    }

    public func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        dragOffset = frame.origin.x - screenPoint.x
        closeButton.isHidden = true
        let dragRect = bounds
        let image = NSImage(data: dataWithPDF(inside: dragRect))
        draggingView = NSImageView(frame: dragRect)
        if let draggingView = draggingView {
            draggingView.layer?.borderColor = self.layer?.borderColor
            draggingView.layer?.borderWidth = self.layer!.borderWidth
            draggingView.image = image
            draggingView.translatesAutoresizingMaskIntoConstraints = false
            tabBar!.addSubview(draggingView)
            draggingView.topAnchor.constraint(equalTo: tabBar!.topAnchor).isActive = true
            draggingView.bottomAnchor.constraint(equalTo: tabBar!.bottomAnchor).isActive = true
            draggingViewLeadingConstraint = draggingView.leadingAnchor
                .constraint(equalTo: leadingAnchor, constant: frame.origin.x)
            draggingViewLeadingConstraint?.isActive = true
        }
        layer?.borderWidth = 0.0
        isDragging = true
        tabTitle.isHidden = true
        needsDisplay = true
    }

    public func draggingSession(_ session: NSDraggingSession, movedTo screenPoint: NSPoint) {
        if let constraint = draggingViewLeadingConstraint,
           let offset = dragOffset, let draggingView = draggingView
        {
            var constant = screenPoint.x + offset
            let min: CGFloat = 0
            if constant < min {
                constant = min
            }
            let max = tabBar!.frame.size.width - configuration.tabWidth
            if constant > max {
                constant = max
            }
            constraint.constant = constant

            tabBar!.handleDraggingTab(draggingRect: draggingView.frame, tab: self)
        }
    }

    public func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        dragOffset = nil
        isDragging = false
        closeButton.isHidden = false
        tabTitle.isHidden = false
        draggingView?.removeFromSuperview()
        draggingViewLeadingConstraint = nil
        needsDisplay = true
        tabBar!.updateTabIndexes()
        layer?.borderWidth = 0.0
    }
}
