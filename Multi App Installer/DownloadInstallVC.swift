//
//  DownloadInstallVC.swift
//  Multi App Installer
//
//  Created by Mark Briggs on 11/20/16.
//  Copyright © 2016 Mark Briggs. All rights reserved.
//

import Cocoa

class DownloadInstallVC: NSViewController, URLSessionDownloadDelegate {

    //let appsToQuery = ["gimp.sh", "teamviewer.sh"]
    var scriptsDirPath: String = ""
    var scriptsToQuery = Array<String>()
    
    var downloadTask: URLSessionDownloadTask!
    
    @IBOutlet weak var appsStackView: NSStackView!
    @IBOutlet weak var selectAllCB: NSButton!
    @IBOutlet weak var actionBtnsStackView: NSStackView!
    @IBOutlet var statusTV: NSTextView!
    @IBOutlet weak var downloadSelectedBtn: NSButton!
    
    @IBOutlet weak var progressView: NSProgressIndicator!
    
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
        //self.view.window?.center()
        
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
            
            // Selection Checkbox (with App Description)
            var selectionCB: NSButton
            if #available(OSX 10.12, *) {
                selectionCB = NSButton(checkboxWithTitle: "App Description", target: nil, action: nil)
            } else {
                // Fallback on earlier versions
                selectionCB = NSButton()
            }
            selectionCB.state = NSOnState
            selectionCB.identifier = scriptToQuery
            
            // Download Status Image View
            var downloadStatusImgView:NSImageView
            if #available(OSX 10.12, *) {
                downloadStatusImgView = NSImageView(image: NSImage(named: "greyQM")!)
            } else {
                // Fallback on earlier versions
                downloadStatusImgView = NSImageView()
                downloadStatusImgView.image = NSImage(named: "greyQM")
                //downloadStatusImgView.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
            }
            downloadStatusImgView.identifier = scriptToQuery
            //downloadStatusImgView.translatesAutoresizingMaskIntoConstraints = true
            
            // Download Button
            var downloadBtn: NSButton
            if #available(OSX 10.12, *) {
                downloadBtn = NSButton(title: NSLocalizedString("Download", comment: "button text"), target: self, action: #selector(downloadBtnClicked))
            } else {
                // Fallback on earlier versions
                downloadBtn = NSButton()
                downloadBtn.title = NSLocalizedString("Download", comment: "button text")
                downloadBtn.target = self
                downloadBtn.action = #selector(downloadBtnClicked)
                downloadBtn.bezelStyle = NSBezelStyle.rounded
                downloadBtn.font = NSFont.systemFont(ofSize: 13.0)
                //downloadBtn.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
            }
            downloadBtn.identifier = scriptToQuery
            //downloadBtn.translatesAutoresizingMaskIntoConstraints = true  // NSStackView bug for 10.9 & 10.10
            
            // Download ImgBtn Stack View
            let downloadImgBtnSV = NSStackView()
            downloadImgBtnSV.spacing = 10
            downloadImgBtnSV.addView(downloadStatusImgView, in: .leading)
            downloadImgBtnSV.addView(downloadBtn, in: .leading)
            
            // Download Progress
            let downloadProgress = NSProgressIndicator()
            downloadProgress.style = .barStyle
            downloadProgress.isIndeterminate = false
            downloadProgress.minValue = 0
            downloadProgress.maxValue = 100
            downloadProgress.doubleValue = 0
            
            // Download Stack View
            let downloadStackView = NSStackView()
            downloadStackView.orientation = .vertical
            downloadStackView.spacing = 0
            downloadStackView.addView(downloadImgBtnSV, in: .top)
            downloadStackView.addView(downloadProgress, in: .top)
            
            
            
            // Install Status Image View
            var installStatusImgView:NSImageView
            if #available(OSX 10.12, *) {
                installStatusImgView = NSImageView(image: NSImage(named: "greyQM")!)
            } else {
                // Fallback on earlier versions
                installStatusImgView = NSImageView()
                installStatusImgView.image = NSImage(named: "greyQM")
                //installStatusImgView.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
            }
            installStatusImgView.identifier = scriptToQuery
            //installStatusImgView.translatesAutoresizingMaskIntoConstraints = true
            
            // Install Button
            var installBtn: NSButton
            if #available(OSX 10.12, *) {
                installBtn = NSButton(title: NSLocalizedString("Install", comment: "button text"), target: self, action: #selector(installBtnClicked))
            } else {
                // Fallback on earlier versions
                installBtn = NSButton()
                installBtn.title = NSLocalizedString("Install", comment: "button text")
                installBtn.target = self
                installBtn.action = #selector(installBtnClicked)
                installBtn.bezelStyle = NSBezelStyle.rounded
                installBtn.font = NSFont.systemFont(ofSize: 13.0)
                //installBtn.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
            }
            installBtn.identifier = scriptToQuery
            
            // Install ImgBtn Stack View
            let installImgBtnSV = NSStackView()
            installImgBtnSV.spacing = 10
            installImgBtnSV.addView(installStatusImgView, in: .leading)
            installImgBtnSV.addView(installBtn, in: .leading)
            
            
            // Install Progress
            let installProgress = NSProgressIndicator()
            installProgress.style = .barStyle
            installProgress.isIndeterminate = false
            installProgress.minValue = 0
            installProgress.maxValue = 100
            installProgress.doubleValue = 0
            
            // Install Stack View
            let installStackView = NSStackView()
            installStackView.orientation = .vertical
            installStackView.spacing = 0
            installStackView.addView(installImgBtnSV, in: .top)
            installStackView.addView(installProgress, in: .top)
            
            // Create Entry StackView
            let entryStackView = NSStackView()  // Default is Horizontal
            entryStackView.alignment = .centerY
            entryStackView.spacing = 10
            //entryStackView.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
            
            // Add all our components to the entry stack view
            entryStackView.addView(selectionCB, in: .leading)
            entryStackView.addView(downloadStackView, in: .leading)
            entryStackView.addView(installStackView, in: .leading)
            
            // Add our entryStackView to the appsStackView
            appsStackView.addView(entryStackView, in: NSStackViewGravity.top)
            
            // Re-center the window on the screen
            //self.view.window?.center()
        }
    }
    
    @IBAction func selectAllCBToggled(_ sender: NSButton) {
        let newState = selectAllCB.state
        
        if newState == NSOnState {
            selectAllCB.title = NSLocalizedString("De-Select All", comment: "De-select all checkbox")
        } else {
            selectAllCB.title = NSLocalizedString("Select All", comment: "Select all checkbox")
        }
        
        for entryStackView in appsStackView.views as! [NSStackView] {
            if let selectionCB = entryStackView.views.first as! NSButton? {
                selectionCB.state = newState
            }
        }
    }
    
    @IBAction func downloadSelectedBtnClicked(_ sender: NSButton) {
        downloadSelectedBtn.isEnabled = false
        makeDownloadCall()
    }
    
    @IBAction func downloadInstallSelectedBtnClicked(_ sender: NSButton) {
        
    }
    
    @IBAction func InstallSelectedBtnClicked(_ sender: NSButton) {
        
    }
    
    @IBAction func quitBtnClicked(_ sender: NSButton) {
        NSApplication.shared().terminate(self)
    }
    
    func downloadBtnClicked(btn: NSButton) {
        let scriptToQuery = btn.identifier ?? ""
        if !scriptToQuery.isEmpty {
            //_ = runTask(taskFilename: scriptToQuery, arguments: ["-w"])  // -w => Write Setting
            
            //fixAsRoot(allFixItScriptsStr: scriptToQuery)
            
            //updateAllStatusImagesAndFixItBtns()
        }
    }

    func installBtnClicked(btn: NSButton) {
        let scriptToQuery = btn.identifier ?? ""
        if !scriptToQuery.isEmpty {
            //_ = runTask(taskFilename: scriptToQuery, arguments: ["-w"])  // -w => Write Setting
            
            //fixAsRoot(allFixItScriptsStr: scriptToQuery)
            
            //updateAllStatusImagesAndFixItBtns()
        }
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
            let logFilePathUrl = cachesDirUrl.appendingPathComponent("multi-app-installer-log.txt")
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
        guard let keepmePath = Bundle.main.path(forResource: "Scripts/KEEPME", ofType:"sh") else {
            printLog(str: "\n  Unable to locate: Scripts/KEEPME.sh!")
            return
        }
        
        scriptsDirPath = String(keepmePath.characters.dropLast(9))  // drop off: "KEEPME.sh"
        if FileManager.default.changeCurrentDirectoryPath(scriptsDirPath) {
            //printLog(str: "success changing dir to: \(scriptsDirPath)")
        } else {
            printLog(str: "failure changing dir to: \(scriptsDirPath)")
        }
    }
    
    func setupScriptsToQueryArray() {
        do {
            var scriptsDirContents = try FileManager.default.contentsOfDirectory(atPath: scriptsDirPath)
            
            // Remove "KEEPME.sh" from the list of scripts.
            if let index = scriptsDirContents.index(of: "KEEPME.sh") {
                scriptsDirContents.remove(at: index)
            }
            
            scriptsToQuery = scriptsDirContents
            printLog(str: "scriptsToQuery: \(scriptsToQuery)")
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
    
    func makeDownloadCall() {
        // Set up the URL request
        //let todoEndpoint: String = "https://jsonplaceholder.typicode.com/todos/1"
        //let todoEndpoint: String = "https://download.gimp.org/mirror/pub/gimp/v2.8/osx/gimp-2.8.16-x86_64-1.dmg"
        let todoEndpoint: String = "http://downloadeu1.teamviewer.com/download/TeamViewerHost.dmg"
        
        guard let url = URL(string: todoEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        let urlRequest = URLRequest(url: url)
        
        // set up the session
        let config = URLSessionConfiguration.default
        //let session = URLSession(configuration: config)
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        
        downloadTask = session.downloadTask(with: urlRequest)
        downloadTask.resume()
    }
    
    //MARK: URLSessionDownloadDelegate
    // 1
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL){
        
        printLog(str: "didFinishDownloadingTo: \(location)")
        
        let fileManager = FileManager()
        var sourceFilePath: String
        if let sourceFolderDefault = UserDefaults.standard.string(forKey: "sourceFolder") {
            sourceFilePath = sourceFolderDefault
        } else {
            sourceFilePath = "/tmp"
        }
        //let destinationURLForFile = URL(fileURLWithPath: "\(sourceFilePath)/GiMp.sh")
        let destinationURLForFile = URL(fileURLWithPath: "\(sourceFilePath)/TeamViewerHost.dmg")
        printLog(str: "destUrlForFile: \(destinationURLForFile)")
        
        if fileManager.fileExists(atPath: destinationURLForFile.path){
            printLog(str: "File already exists! Removing it!")
            do {
                try fileManager.removeItem(at: destinationURLForFile)
            }catch{
                print("An error occurred while removing file at destination url")
            }
        }
            
        // Move item from temp dir to desination dir
        printLog(str: "Moving item from temp to destination")
        do {
            try fileManager.moveItem(at: location, to: destinationURLForFile)
        }catch{
            print("An error occurred while moving file to destination url")
        }
    }
    // 2
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64){
        //printLog(str: "dl in progress: \(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100)")
        
        progressView.doubleValue = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
    }

    
    //MARK: URLSessionTaskDelegate
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?){
        downloadTask = nil
        progressView.doubleValue = 0.0
        downloadSelectedBtn.isEnabled = true
        if (error != nil) {
            print(error!.localizedDescription)
        }else{
            print("The task finished transferring data successfully")
        }
    }
}
