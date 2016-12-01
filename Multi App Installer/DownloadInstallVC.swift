//
//  DownloadInstallVC.swift
//  Multi App Installer
//
//  Created by Mark Briggs on 11/20/16.
//  Copyright © 2016 Mark Briggs. All rights reserved.
//

import Cocoa

class DownloadInstallVC: NSViewController {

    //let appsToQuery = ["gimp.sh", "teamviewer.sh"]
    var scriptsDirPath: String = ""
    var scriptsToQuery = Array<String>()
    
    @IBOutlet weak var appsStackView: NSStackView!
    @IBOutlet weak var selectAllCB: NSButton!
    @IBOutlet weak var actionBtnsStackView: NSStackView!
    @IBOutlet var statusTV: NSTextView!
    
    override func loadView() {
        // Adding this function so older OS's (eg <=10.9) can still call our viewDidLoad() function
        // Seems this function is called for older OS's (eg 10.9) and newer ones as well (eg. 10.12)
        
        // Output Timestamp
        let d = Date()
        let df = DateFormatter()
        df.dateFormat = "y-MM-dd HH:mm:ss"
        let timestamp = df.string(from: d)
        printLog(str: "=====================")
        printLog(str: "[" + timestamp + "]")
        printLog(str: "=====================")
        
        printLog(str: "loadView()")
        super.loadView()
        
        if floor(NSAppKitVersionNumber) <= Double(NSAppKitVersionNumber10_9) {  // This check is necessary, because even in 10.12 loadView() is called.
            printLog(str: "  calling self.viewDidLoad() from loadView()")
            self.viewDidLoad() // call viewDidLoad (added in 10.10)
        }
    }
    
    override func viewDidLoad() {
        printLog(str: "viewDidLoad()")
        if #available(OSX 10.10, *) {
            printLog(str: "  super.viewDidLoad()")
            super.viewDidLoad()
        } else {
            printLog(str: "  NOT calling super.viewDidLoad() [because 10.9 or lower is being used.")
            // No need to do anything here because 10.9 and older will have went through the loadView() function & that calls super.loadView()
        }
        
        // Delay a bit, THEN initEverything, so we can see the animation in the GUI.
        // Also makes it so Winodw is ALWAYS on top of other apps when starting the app.
        let deadlineTime = DispatchTime.now() + 0.5
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.initEverything()
        }
    }
    
    func initEverything() {
        // Change current directory to script's dir for rest of App's lifetime
        changeCurrentDirToScriptsDir()
        
        // Find all scripts/settings we need to query
        setupScriptsToQueryArray()
        
        // Re-center the window on the screen
        self.view.window?.center()
        
        // Make sure user's OS is Yosemite or higher. Yosemite (10.10.x) [14.x.x]. If not, tell user & Quit App.
        let minReqOsVer = OperatingSystemVersion(majorVersion: 10, minorVersion: 10, patchVersion: 0)  // Yosemite
        let userOsVer = getUserOsVersion()
        if userOsVer.majorVersion < minReqOsVer.majorVersion {
            alertTooOldAndQuit(userOsVer: userOsVer)
        } else if (userOsVer.majorVersion == minReqOsVer.majorVersion) && (userOsVer.minorVersion < minReqOsVer.minorVersion) {
            alertTooOldAndQuit(userOsVer: userOsVer)
        }
        
        // Add (Version Number) to title of Main GUI's Window
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let appVersion = Bundle.main.infoDictionary![kCFBundleVersionKey as String] as! String
        self.view.window?.title = "\(appName) (v\(appVersion))"
        
        // Build the list of Apps for the Main GUI
        for scriptToQuery in scriptsToQuery {
            
            
            
            
            
            // Re-center the window on the screen
            self.view.window?.center()
        }
        
    }
    
    
    @IBAction func downloadSelectedBtnClicked(_ sender: NSButton) {
        
    }
    
    @IBAction func downloadInstallSelectedBtnClicked(_ sender: NSButton) {
        
    }
    
    @IBAction func InstallSelectedBtnClicked(_ sender: NSButton) {
        
    }
    
    func alertTooOldAndQuit(userOsVer: OperatingSystemVersion) {
        printLog(str: "OS Version is TOO OLD: \(userOsVer)")
        _ = osVerTooOldAlert(userOsVer: userOsVer)
        NSApplication.shared().terminate(self)  // Quit App no matter what.
    }
    
    func osVerTooOldAlert(userOsVer: OperatingSystemVersion) -> Bool {
        let alert: NSAlert = NSAlert()
        
        alert.messageText = NSLocalizedString("Operating System Outdated", comment: "os outdated")
        alert.informativeText = String.localizedStringWithFormat(NSLocalizedString("Your operating system is too old. It must first be updated to AT LEAST Yosemite (10.10) before this app will run. Your OS Version is: [%d.%d.%d]", comment: "os too old message"), userOsVer.majorVersion, userOsVer.minorVersion, userOsVer.patchVersion)
        
        alert.alertStyle = NSAlertStyle.informational
        alert.addButton(withTitle: NSLocalizedString("Quit", comment: ""))
        return alert.runModal() == NSAlertFirstButtonReturn
    }
    
    func printLog(str: String) {
        printLog(str: str, terminator: "\n")
    }
    
    func printLog(str: String, terminator: String) {
        
        // First tidy-up str a bit
        var prettyStr = str.replacingOccurrences(of: "\r\n", with: "\n") // just incase
        prettyStr = prettyStr.replacingOccurrences(of: "\r", with: "\n") // becasue AppleScript returns line endings with '\r'
        
        // Normal print
        print(prettyStr, terminator: terminator)
        
        // Print to log file
        if let cachesDirUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let logFilePathUrl = cachesDirUrl.appendingPathComponent("security-fixer-upper-log.txt")
            let logData = (prettyStr + terminator).data(using: .utf8, allowLossyConversion: false)!
            
            if FileManager.default.fileExists(atPath: logFilePathUrl.path) {
                do {
                    let logFileHandle = try FileHandle(forWritingTo: logFilePathUrl)
                    logFileHandle.seekToEndOfFile()
                    logFileHandle.write(logData)
                    logFileHandle.closeFile()
                } catch {
                    print("Unable to write to existing log file, at this path: \(logFilePathUrl.path)")
                }
            } else {
                do {
                    try logData.write(to: logFilePathUrl)
                } catch {
                    print("Can't write to new log file, at this path: \(logFilePathUrl.path)")
                }
            }
        }
    }
    
    func changeCurrentDirToScriptsDir() {
        guard let runWsPath = Bundle.main.path(forResource: "Scripts/runWs", ofType:"sh") else {
            printLog(str: "\n  Unable to locate: Scripts/runWs.sh!")
            return
        }
        
        scriptsDirPath = String(runWsPath.characters.dropLast(8))  // drop off: "runWs.sh"
        if FileManager.default.changeCurrentDirectoryPath(scriptsDirPath) {
            //printLog(str: "success changing dir to: \(scriptsDirPath)")
        } else {
            printLog(str: "failure changing dir to: \(scriptsDirPath)")
        }
    }
    
    func setupScriptsToQueryArray() {
        do {
            var scriptsDirContents = try FileManager.default.contentsOfDirectory(atPath: scriptsDirPath)
            
            // Remove "runWs.sh" from the list of scripts.
            if let index = scriptsDirContents.index(of: "runWs.sh") {
                scriptsDirContents.remove(at: index)
            }
            
            scriptsToQuery = scriptsDirContents
        } catch {
            printLog(str: "Cannot get contents of Scripts dir: \(scriptsDirPath)")
        }
    }
    
    func getUserOsVersion() -> OperatingSystemVersion {
        var userOsVer:OperatingSystemVersion
        if #available(OSX 10.10, *) {
            userOsVer = ProcessInfo().operatingSystemVersion
        } else {
            // Fallback on earlier versions
            if (floor(NSAppKitVersionNumber) <= Double(NSAppKitVersionNumber10_6)) {
                //10.6.x or earlier systems
                userOsVer = OperatingSystemVersion(majorVersion: 10, minorVersion: 6, patchVersion: 0)
            } else if (floor(NSAppKitVersionNumber) <= Double(NSAppKitVersionNumber10_7)) {
                userOsVer = OperatingSystemVersion(majorVersion: 10, minorVersion: 7, patchVersion: 0)
            } else if (floor(NSAppKitVersionNumber) <= Double(NSAppKitVersionNumber10_8)) {
                userOsVer = OperatingSystemVersion(majorVersion: 10, minorVersion: 8, patchVersion: 0)
            } else if (floor(NSAppKitVersionNumber) <= Double(NSAppKitVersionNumber10_9)) {
                userOsVer = OperatingSystemVersion(majorVersion: 10, minorVersion: 9, patchVersion: 0)
            } else {
                // Should never get here, but just in case
                userOsVer = OperatingSystemVersion(majorVersion: 10, minorVersion: 0, patchVersion: 0)
            }
        }
        
        return userOsVer
    }
}
