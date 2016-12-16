//
//  LanguageChooserVC.swift
//  Multi App Installer
//
//  Created by Mark Briggs on 12/8/16.
//  Copyright © 2016 Mark Briggs. All rights reserved.
//

import Cocoa

class LanguageChooserVC: NSViewController {

    @IBOutlet weak var languagePUBtn: NSPopUpButton!
    @IBOutlet weak var okBtn: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currLangIso = Fn.getCurrLangIso()
        switch currLangIso {
        case "en":
            languagePUBtn.selectItem(withTitle: "English")
        case "tr":
            languagePUBtn.selectItem(withTitle: "Türkçe")
        case "ru":
            languagePUBtn.selectItem(withTitle: "Русский")
        default:
            // Case where unknown/unsupported language exists on system.
            languagePUBtn.selectItem(withTitle: "English")
        }
    }
    
    @IBAction func okBtnClicked(_ sender: NSButton) {
        if let selectedId = languagePUBtn.selectedItem?.toolTip {
            if selectedId == Fn.getCurrLangIso() {
                // Dismiss this modal View Controller
                self.dismiss(self)
            } else {
                // Change to new language & restart app
                UserDefaults.standard.setValue([selectedId], forKey: "AppleLanguages")
                UserDefaults.standard.setValue(true, forKey: "SkipLanguageDialogBoxOnNextStartup")
                UserDefaults.standard.synchronize()
                selfRestart()
            }
        }
    }
    
    func selfRestart() {
        let task = Process()
        task.launchPath = "/bin/sh"
        //task.arguments = ["-c", "sleep 0.3; open \"\(Bundle.main.bundlePath)\""]
        task.arguments = ["-c", "open \"\(Bundle.main.bundlePath)\""]
        task.launch()
        NSApplication.shared().terminate(nil)
    }
}
