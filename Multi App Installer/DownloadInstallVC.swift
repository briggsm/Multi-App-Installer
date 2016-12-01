//
//  DownloadInstallVC.swift
//  Multi App Installer
//
//  Created by Mark Briggs on 11/20/16.
//  Copyright © 2016 Mark Briggs. All rights reserved.
//

import Cocoa

class DownloadInstallVC: NSViewController {

    let appsToQuery = ["gimp.sh", "teamviewer.sh"]
    // TODO - change this to go look in (external) directory & fill this array based on directory contents
    
    @IBOutlet weak var appsStackView: NSStackView!
    @IBOutlet weak var selectAllCB: NSButton!
    @IBOutlet weak var actionBtnsStackView: NSStackView!
    @IBOutlet var statusTV: NSTextView!
    
    
    override func viewDidAppear() {
        // Add (Version Number) to title of Main GUI's Window
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let appVersion = Bundle.main.infoDictionary![kCFBundleVersionKey as String] as! String
        self.view.window?.title = "\(appName) (v\(appVersion))"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Build the list of Applications for the Main GUI
        for appToQuery in appsToQuery {
            
        }
    }
    
    
    @IBAction func downloadSelectedBtnClicked(_ sender: NSButton) {
        
    }
    
    @IBAction func downloadInstallSelectedBtnClicked(_ sender: NSButton) {
        
    }
    
    @IBAction func InstallSelectedBtnClicked(_ sender: NSButton) {
        
    }
}
