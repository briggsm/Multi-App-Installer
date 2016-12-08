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
    @IBOutlet weak var restartBtn: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setOnlyOkBtnEnabled()
        
        let currLangIso = getCurrLangIso()
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
            setOnlyRestartBtnEnabled()
        }
    }
    
    @IBAction func languagePUBtnSelected(_ sender: NSPopUpButton) {
        print("languagePUBtnSelected")
        let currLangIso = getCurrLangIso()
        print("currLangIso: \(currLangIso)")
        
        // test - not working...
        if let selectedRealId = languagePUBtn.selectedItem?.identifier {
            print("selectedId(ident) \(selectedRealId)")
        }
        
        if let selectedId = languagePUBtn.selectedItem?.accessibilityIdentifier() {
            print("selectedId(accessIdent): \(selectedId)")
            if currLangIso == selectedId {
                setOnlyOkBtnEnabled()
            } else {
                setOnlyRestartBtnEnabled()
            }
        }
    }
    
    @IBAction func okBtnClicked(_ sender: NSButton) {
        self.dismiss(self)
    }
    
    @IBAction func restartBtnClicked(_ sender: NSButton) {
        if let selectedId = languagePUBtn.selectedItem?.accessibilityIdentifier() {
            UserDefaults.standard.setValue([selectedId], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            NSApplication.shared().terminate(self)
        }
    }
    
    func getCurrLangIso() -> String {
        let currLangArr = UserDefaults.standard.value(forKey: "AppleLanguages") as! Array<String>
        
        var currLangIso = currLangArr[0]
        
        // Chop off everything except 1st two characters
        currLangIso = currLangIso.substring(to: currLangIso.index(currLangIso.startIndex, offsetBy: 2))
        
        return currLangIso
    }
    
    func setOnlyOkBtnEnabled() {
        okBtn.isEnabled = true
        restartBtn.isEnabled = false
    }
    
    func setOnlyRestartBtnEnabled() {
        restartBtn.isEnabled = true
        okBtn.isEnabled = false
    }
}
