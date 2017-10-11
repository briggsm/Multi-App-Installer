//
//  AppsStackView.swift
//  Multi App Installer
//
//  Created by Mark Briggs on 10/11/17.
//  Copyright © 2017 Mark Briggs. All rights reserved.
//

import Cocoa

/* Note: added this class only for purpose of overriding 'isFlipped', so scroll view's 'content view' is attached to upper-left, not lower-left */
class AppsStackView: NSStackView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override var isFlipped: Bool {
        get {
            return true
        }
    }
    
}
