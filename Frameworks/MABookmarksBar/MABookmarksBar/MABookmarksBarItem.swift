//
//  MABookmarksBarItem.swift
//  MABookmarksBar
//
//  Created by Ashwin Paudel on 2022-02-15.
//

import Cocoa

open class MABookmarksBarItem: NSButton {
    open var item: MABookmarksItem
    public let tabTitle = NSTextField(frame: .zero)
    var xPosition: CGFloat = 4
    var yPosition: CGFloat = 2

    public required init(frame frameRect: NSRect, item: MABookmarksItem) {
        self.item = item
        super.init(frame: frameRect)
        configureViews()
    }

    private final func configureViews() {
        let position = xPosition * 2

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

        tabTitle.stringValue = item.title
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func updateColors(background: NSColor, titleColor: NSColor) {
        wantsLayer = true
        tabTitle.textColor = titleColor
        layer?.backgroundColor = background.cgColor
        (cell as? NSButtonCell)?.backgroundColor = background
    }
}
