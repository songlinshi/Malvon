//
//  MubDownloadsTableViewCell.swift
//  Mubser
//
//  Created by Ashwin Paudel on 2021-12-28.
//  Copyright © 2021 Ashwin Paudel. All rights reserved.
//

import Cocoa

class MubDownloadsTableViewCell: NSTableCellView {
    
    @IBOutlet weak var MubFileIcon: NSImageView!
    @IBOutlet weak var MubFileName: NSTextField!
    @IBOutlet weak var MubLocation: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.layer?.cornerRadius = 15
        // Drawing code here.
    }
    
}