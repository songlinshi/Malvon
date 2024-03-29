//
//  MATabView.swift
//  MATabView
//
//  Created by Ashwin Paudel on 2022-01-06.
//  Copyright © 2021-2022 Ashwin Paudel. All rights reserved.
//

import Cocoa

@objc public protocol MATabViewDelegate: NSObjectProtocol {
    // Select Functions
    @objc optional func tabView(_ tabView: MATabView, willSelect tab: MATab, colorConfig: MATabViewConfiguration)
    @objc optional func tabView(_ tabView: MATabView, didSelect tab: MATab, colorConfig: MATabViewConfiguration)

    // Close Functions
    @objc optional func tabView(_ tabView: MATabView, willClose tab: MATab)
    @objc optional func tabView(_ tabView: MATabView, didClose tab: MATab)

    // Create New Tab Function
    @objc optional func tabView(_ tabView: MATabView, willCreateTab tab: MATab)
    @objc optional func tabView(_ tabView: MATabView, didCreateTab tab: MATab)

    // When there are no more tabs left
    @objc optional func tabView(noMoreTabsLeft tabView: MATabView)
}

open class MATabView: NSView, MATabBarDelegate {
    open var selectedTab: MATab?
    open var tabs = [MATab]()
    open var hiddenTabs = [MATab]()
    open weak var delegate: MATabViewDelegate?
    open var tabBar = MATabBar(frame: .zero)

    open var configuration = MATabViewConfiguration()

    // MARK: - Configuring

    private final func configureViews() {
        tabBar.delegate = self
        tabBar.tabView = self
        addSubview(tabBar)

        tabBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tabBar.heightAnchor.constraint(equalToConstant: configuration.tabHeight),
            tabBar.topAnchor.constraint(equalTo: topAnchor),
            tabBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let bgColor: NSColor = .white
        layer?.masksToBounds = true
        layer?.backgroundColor = bgColor.cgColor
        bgColor.setFill()
        dirtyRect.fill()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }

    override public required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureViews()
    }

    // MARK: - Tabs Controls

    open func select(tab: Int) {
        select(tab: tabs[tab])
    }

    open func updateTabIndexes(tabs: [MATab]) {
        self.tabs = tabs
        for (index, tab) in self.tabs.enumerated() {
            tab.position = index
        }
    }

    open func select(tab: MATab, isNewTab: Bool = false) {
        delegate?.tabView?(self, willSelect: tab, colorConfig: tabBar.get(tabItem: tab.position).configuration)

        if !(tabBar.isEmpty()) {
            let oldTab = tabBar.get(tabItem: selectedTab!.position)
            oldTab.animator().alphaValue = 0.6
            oldTab.isSelectedTab = false
        }

        selectedTab?.isSelectedTab = false

        selectedTab?.view.removeFromSuperview()

        let frameSize = NSSize(width: frame.width, height: frame.height - 30)

        tab.view.setFrameSize(frameSize)
        addSubview(tab.view)
        tab.view.autoresizingMask = [.width, .height]

        selectedTab = tab
//
        if !isNewTab {
            let newTab = tabBar.get(tabItem: tab.position)
            updateColors(configuration: tabBar.get(tabItem: selectedTab!.position).configuration)
            newTab.alphaValue = 0.0
            newTab.isSelectedTab = true

            newTab.animator().alphaValue = 1.0
        }

        selectedTab!.isSelectedTab = true

        if isNewTab {
            delegate?.tabView?(self, didSelect: tab, colorConfig: configuration)
        } else {
            delegate?.tabView?(self, didSelect: tab, colorConfig: configuration)
        }
    }

    open func create(tab: MATab) {
        delegate?.tabView?(self, willCreateTab: tab)

        // Configure the tab
        tab.position = tabs.count

        tabs.append(tab)
        select(tab: tab, isNewTab: true)
        tabBar.add(tab: tab)

        delegate?.tabView?(self, didCreateTab: tab)
    }

    open func remove(tab: Int) {
        remove(tab: tabs[tab])
    }

    open func remove(tab: MATab) {
        delegate?.tabView?(self, willClose: tab)

        if tabs.isEmpty || tabBar.tabCount == 1 {
            delegate?.tabView?(noMoreTabsLeft: self)
            return
                // Check if the user is on the tab that will be removed
        } else if selectedTab?.position == tab.position {
            if (tabs.count - 1) != 0 || (tabs.count - 1) == 1 {
                if selectedTab?.position == 0 {
                    selectedTab = tabs[selectedTab!.position + 1]
                } else {
                    selectedTab = tabs[selectedTab!.position - 1]
                }
                select(tab: selectedTab!)
            }
        } else {
            select(tab: selectedTab!)
        }

        tabs.remove(at: tab.position)
        tabBar.remove(tab: tab)

        for (index, tab) in tabs.enumerated() {
            tab.position = index
        }

        delegate?.tabView?(self, didClose: tab)
    }

    // MARK: - Tab Bar

    public func tabBar(_ tabBarView: MATabBar, didSelect tab: MATab) {
        select(tab: tab)
    }

    public func tabBar(_ tabBarView: MATabBar, wantsToClose tab: MATab) {
        remove(tab: tab)
    }

    public func tabBar(wantsToDisplayHiddenItemMenu tabBarView: MATabBar) -> [MATab] {
        return hiddenTabs
    }

    public func tabBar(wantsToUnhide tabBarView: MATabBar, at position: Int) {
        tabs.append(hiddenTabs[position])

        for (index, tab) in tabs.enumerated() {
            tab.position = index
        }

        tabBar.add(tab: hiddenTabs[position])
        hiddenTabs.remove(at: position)

        select(tab: position)
    }

    public func tabBar(_ tabBarView: MATabBar, wantsToHide tab: MATab) {
        if selectedTab?.position == tab.position {
            if (tabs.count - 1) != 0 || (tabs.count - 1) == 1 {
                if selectedTab?.position == 0 {
                    selectedTab = tabs[selectedTab!.position + 1]
                } else {
                    selectedTab = tabs[selectedTab!.position - 1]
                }
                select(tab: selectedTab!)
            }
        }

        tab.view.removeFromSuperview()

        hiddenTabs.append(tab)
        tabs.remove(at: tab.position)
        tabBar.remove(tab: tab)

        for (index, tab) in tabs.enumerated() {
            tab.position = index
        }
    }

    public func tabBar(wantsToUnhideAllTabs tabBarView: MATabBar) {
        tabs.append(contentsOf: hiddenTabs)
        for (index, tab) in tabs.enumerated() {
            tab.position = index
        }

        for tab in hiddenTabs {
            tabBar.add(tab: tab)
        }

        hiddenTabs.removeAll()
    }

    // MARK: - Get & Set

    open func get(tab at: Int) -> MATab {
        tabs[at]
    }

    open func set(tab at: Int, title: String) {
        tabs[at].title = title
        tabBar.get(tabItem: at).tab.title = title
        tabBar.get(tabItem: at).tabTitle.stringValue = title
    }

    open func set(tab at: Int, icon: NSImage) {
        tabs[at].icon = icon
        tabBar.get(tabItem: at).tab.icon = icon
        tabBar.get(tabItem: at).closeButton.image = icon
    }

    open func updateColors(configuration: MATabViewConfiguration) {
        self.configuration = configuration
        tabBar.heightAnchor.constraint(equalToConstant: configuration.tabHeight).isActive = true
        tabBar.updateColors(configuration: configuration, selectedTab: selectedTab!)
    }
}
