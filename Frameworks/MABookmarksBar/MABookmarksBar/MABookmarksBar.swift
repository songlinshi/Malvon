//
//  MABookmarksBar.swift
//  MABookmarksBar
//
//  Created by Ashwin Paudel on 2022-02-15.
//

import Cocoa

final class FlippedView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}

@objc public protocol MABookmarksBarDelegate: NSObjectProtocol {
    @objc optional func bookmarksBar(_ bookmarksBar: MABookmarksBar, selected item: MABookmarksItem)
}

open class MABookmarksBar: NSView, MABookmarksBarDelegate {
    private let stackView = NSStackView()
    private let scrollView = NSScrollView()
    private let containerView = FlippedView()
    open weak var delegate: MABookmarksBarDelegate?

    // Configuration
    open var barHeight: CGFloat = 30
    open var barItemWidth: CGFloat = 100

    // MARK: - Configuring

    private final func configureViews() {
        wantsLayer = true

        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = false
        scrollView.hasVerticalRuler = false
        scrollView.drawsBackground = false
        scrollView.verticalScrollElasticity = .none

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: barHeight)
        ])

        containerView.drawsBackground = false
        scrollView.contentView = containerView
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        scrollView.documentView = stackView
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        stackView.orientation = .horizontal
        stackView.distribution = .gravityAreas
        stackView.alignment = .centerY
        stackView.spacing = 0.5
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        wantsLayer = true
//        let appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
//
//        if appearance == "Dark" {
//            layer?.backgroundColor = configuration.darkTabBackgroundColor.cgColor
//        } else {
//            layer?.backgroundColor = configuration.lightTabBackgroundColor.cgColor
//        }
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }

    override public required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureViews()
    }

    // MARK: - Tab Functions

    open func move(item: MABookmarksBarItem, at: Int) {
        stackView.insertArrangedSubview(item, at: at)

        for (index, subview) in stackView.arrangedSubviews.enumerated() {
            (subview as! MABookmarksBarItem).item.position = index
        }
    }

    open func remove(item: MABookmarksItem) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true

            stackView.arrangedSubviews[item.position].alphaValue = 0.0
        } completionHandler: { [self] in
            stackView.arrangedSubviews[item.position].removeFromSuperview()
        }
        // Remap the position of each tab
        for (index, subview) in stackView.arrangedSubviews.enumerated() {
            (subview as! MABookmarksBarItem).item.position = index
        }
    }

    open func updateTabIndexes() {
        for (index, subview) in stackView.arrangedSubviews.enumerated() {
            (subview as! MABookmarksBarItem).item.position = index
        }
    }

    open func add(item: MABookmarksItem) {
        let newButton = MABookmarksBarItem(frame: .zero, item: item)

        newButton.translatesAutoresizingMaskIntoConstraints = false
        newButton.heightAnchor.constraint(equalToConstant: barHeight).isActive = true
        newButton.widthAnchor.constraint(equalToConstant: barItemWidth).isActive = true
        newButton.tag = stackView.subviews.count
//        newButton.configuration = configuration

        newButton.title = ""
        newButton.target = self
        newButton.action = #selector(selectedTab(_:))
        newButton.wantsLayer = true

        newButton.bezelStyle = .shadowlessSquare

        stackView.addArrangedSubview(newButton)
    }

    @objc func selectedTab(_ sender: MABookmarksBarItem) {
        delegate?.bookmarksBar?(self, selected: sender.item)
    }

    // MARK: - Get

    open func isEmpty() -> Bool {
        return stackView.arrangedSubviews.isEmpty
    }

    public func get(tabItem at: Int) -> MABookmarksBarItem {
        return stackView.arrangedSubviews[at] as! MABookmarksBarItem
    }

    public var tabCount: Int {
        return stackView.arrangedSubviews.count
    }

    open func updateColors(selectedTab: MABookmarksItem) {
//        self.configuration = configuration
        scrollView.heightAnchor.constraint(equalToConstant: barHeight).isActive = true
//        let appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
//
//        if appearance == "Dark" {
//            layer?.backgroundColor = configuration.darkTabBackgroundColor.cgColor
//        } else {
//            layer?.backgroundColor = configuration.lightTabBackgroundColor.cgColor
//        }
//
//        for view in stackView.arrangedSubviews {
//            (view as! MABookmarksBarItem).updateColors(configuration: configuration)
//        (stackView.arrangedSubviews[selectedTab.position] as! MABookmarksItem).updateColors(configuration: configuration)
//        }
    }
}
