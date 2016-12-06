//
//  SettingsVC.swift
//  Multi App Installer
//
//  Created by Mark Briggs on 11/20/16.
//  Copyright © 2016 Mark Briggs. All rights reserved.
//

import Cocoa

class SettingsVC: NSViewController {

    @IBOutlet weak var scriptsFolderTF: NSTextField!
    @IBOutlet weak var sourceFolderTF: NSTextField!
    @IBOutlet weak var enableInstallPreAppsCB: NSButton!  // Enable Install Button for Already (Pre) Installed Apps
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // Init scriptsFolderTF
//        if let scriptsFolderDefault = UserDefaults.standard.string(forKey: "scriptsFolder") {
//            scriptsFolderTF.stringValue = scriptsFolderDefault
//        } else {
//            scriptsFolderTF.stringValue = "/tmp"
//        }
        
        // Init sourceFolderTF
        if let sourceFolderDefault = UserDefaults.standard.string(forKey: "sourceFolder") {
            sourceFolderTF.stringValue = sourceFolderDefault
        } else {
            sourceFolderTF.stringValue = "/tmp"
            UserDefaults.standard.setValue("/tmp", forKey: "sourceFolder")
        }
        
        // Init enableInstallPreAppsCB
        let enableInstallPreAppsDefault = UserDefaults.standard.bool(forKey: "enableInstallPreApps")
        enableInstallPreAppsCB.state = enableInstallPreAppsDefault ? NSOnState : NSOffState
    }
    
//    @IBAction func scriptsFolderBrowseBtnClicked(_ sender: NSButton) {
//        let openPanel = NSOpenPanel()
//        openPanel.title = "Choose a Folder"
//        openPanel.allowsMultipleSelection = false
//        openPanel.canChooseDirectories = true
//        openPanel.canCreateDirectories = true
//        openPanel.canChooseFiles = false
//        if (openPanel.runModal() == NSModalResponseOK) {
//            self.scriptsFolderTF.stringValue = openPanel.urls[0].path
//            
//            // Save to UserDefaults
//            UserDefaults.standard.setValue(scriptsFolderTF.stringValue, forKey: "scriptsFolder")
//        }
//    }
    
    @IBAction func sourceFolderBrowseBtnClicked(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose a Folder"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        if (openPanel.runModal() == NSModalResponseOK) {
            self.sourceFolderTF.stringValue = openPanel.urls[0].path
            
            // Save to UserDefaults
            UserDefaults.standard.setValue(sourceFolderTF.stringValue, forKey: "sourceFolder")
        }
    }
    
    @IBAction func enableInstallPreAppsCBToggled(_ sender: NSButton) {
        // Save to UserDefaults
        UserDefaults.standard.setValue(sender.state == NSOnState ? true : false, forKey: "enableInstallPreApps")
    }
    
}
