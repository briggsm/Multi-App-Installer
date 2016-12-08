//
//  SettingsVC.swift
//  Multi App Installer
//
//  Created by Mark Briggs on 11/20/16.
//  Copyright © 2016 Mark Briggs. All rights reserved.
//

import Cocoa

class SettingsVC: NSViewController {

    @IBOutlet weak var sourceFolderTF: NSTextField!
    @IBOutlet weak var enableInstallPreAppsCB: NSButton!  // Enable Install Button for Already (Pre) Installed Apps
    
    override func viewWillDisappear() {
        //print("**view will DISAPPEAR**")
        if FileManager.default.fileExists(atPath: sourceFolderTF.stringValue) {
            // Save sourceFolderTF to UserDefaults
            UserDefaults.standard.setValue(sourceFolderTF.stringValue, forKey: "sourceFolder")
        } else {
            //alertSourceFolderDoesNotExist()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    @IBAction func sourceFolderTFFocusLeft(_ sender: NSTextField) {
        if !FileManager.default.fileExists(atPath: sourceFolderTF.stringValue) {
            alertSourceFolderDoesNotExist()
        }
    }
    
    @IBAction func sourceFolderBrowseBtnClicked(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose a Folder"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        if (openPanel.runModal() == NSModalResponseOK) {
            self.sourceFolderTF.stringValue = openPanel.urls[0].path
        }
    }
    
    @IBAction func enableInstallPreAppsCBToggled(_ sender: NSButton) {
        // Save to UserDefaults
        UserDefaults.standard.setValue(sender.state == NSOnState ? true : false, forKey: "enableInstallPreApps")
    }
    
    func alertSourceFolderDoesNotExist() {
        let alert: NSAlert = NSAlert()
        alert.messageText = "Source Folder does not exist!"
        alert.informativeText = "You must choose an existing folder!"
        _ = alert.runModal()
    }
}
