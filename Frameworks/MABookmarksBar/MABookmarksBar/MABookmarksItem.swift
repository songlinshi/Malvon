//
//  MABookmarksBarItem.swift
//  MABookmarksBar
//
//  Created by Ashwin Paudel on 2022-02-15.
//

import Cocoa

open class MABookmarksItem: NSObject {
    open var title: String
    open var url: URL?

    // The position of the item
    public var position: Int = 0

    public init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
}
