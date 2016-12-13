//
//  DownloadInstallVC.swift
//  Multi App Installer
//
//  Created by Mark Briggs on 11/20/16.
//  Copyright © 2016 Mark Briggs. All rights reserved.
//

import Cocoa

struct AppMeta {
    var appDescription: String
    var downloadUrl: URL
    var saveAsFilename: String
    var installUser: String  // "root" or "user"
    var proofAppExistsPaths: [String]
}

class DownloadInstallVC: NSViewController {

    // MARK: Scripts
    var scriptsDirPath: String = ""
    var scriptsToQuery = [String]()
    
    // MARK: Session
    var urlSession: URLSession = URLSession()
    
    // MARK: Defaults
    var sourceFolder = UserDefaults.standard.string(forKey: "sourceFolder") ?? "/tmp"
    var enableInstallPreApps = UserDefaults.standard.bool(forKey: "enableInstallPreApps")
    
    // MARK: Dictionaries
    var appMetaDict = [String : AppMeta]()
    
    var downloadStatusImgViewDict = [String : NSImageView]()
    var downloadBtnDict = [String : NSButton]()
    var downloadProgressIndicatorDict = [String : NSProgressIndicator]()
    var isDownloadingDict = [String : Bool]()
    
    var installStatusImgViewDict = [String : NSImageView]()
    var installBtnDict = [String : NSButton]()
    var installProgressIndicatorDict = [String : NSProgressIndicator]()
    var isInstallingDict = [String : Bool]()
    
    // MARK: Outlets
    @IBOutlet weak var appsStackView: NSStackView!
    @IBOutlet var statusTV: NSTextView!
    @IBOutlet weak var downloadSelectedBtn: NSButton!
    @IBOutlet weak var selectAllBtn: NSButton!
    
    // MARK: - Initial Loading Functions
    override func viewDidAppear() {
        //printLog(str: "*viewDidAppear()*")
        
        sourceFolder = UserDefaults.standard.string(forKey: "sourceFolder") ?? "/tmp"
        enableInstallPreApps = UserDefaults.standard.bool(forKey: "enableInstallPreApps")
        
        refreshAllGuiViews()
    }
    
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
        // And gives time for viewDidAppear() to execute first.
        let deadlineTime = DispatchTime.now() + 0.5
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.initEverything()
        }
    }
    
    func initEverything() {
        
        // Init Session for Downloading files.
        let config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        
        // Change current directory to script's dir for rest of App's lifetime
        changeCurrentDirToScriptsDir()
        
        // Find all scripts/settings we need to query
        setupScriptsToQueryArray()
        
        // Re-center the window on the screen
        //self.view.window?.center()
        
        // Add (Version Number) to title of Main GUI's Window
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let appVersion = Bundle.main.infoDictionary![kCFBundleVersionKey as String] as! String
        self.view.window?.title = "\(appName) (v\(appVersion))"
        
        // Build the list of Apps for the Main GUI
        for scriptToQuery in scriptsToQuery {
            
            // Add to appMetaDict. Continue loop if anything looks wrong.
            let appMetaTaskOutput = runSyncTaskAsUser(scriptToQuery: scriptToQuery, arguments: ["-appMeta", getCurrLangIso()])
            if appMetaTaskOutput != "" {
                let appMetaArr = appMetaTaskOutput.components(separatedBy: "||")
                
                // TODO - maybe add some sanity checks here...
                guard let downloadUrl = URL(string: appMetaArr[1]) else {
                    printLog(str: "Error: cannot create URL from this string: \(appMetaArr[1])")
                    continue  // to next iteration of for loop
                }
                
                let proofAppExistsPathsArr = appMetaArr[4].components(separatedBy: "|")
                appMetaDict[scriptToQuery] = AppMeta(appDescription: appMetaArr[0], downloadUrl: downloadUrl, saveAsFilename: appMetaArr[2], installUser: appMetaArr[3], proofAppExistsPaths: proofAppExistsPathsArr)
            }
            
            if let appMeta = appMetaDict[scriptToQuery] {
                // Selection Checkbox (with App Description)
                var selectionCB: NSButton
                if #available(OSX 10.12, *) {
                    selectionCB = NSButton(checkboxWithTitle: appMeta.appDescription, target: nil, action: nil)
                } else {
                    // Fallback on earlier versions
                    selectionCB = NSButton()
                    selectionCB.title = appMeta.appDescription
                    selectionCB.setButtonType(.switch)
                    selectionCB.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                }
                selectionCB.state = NSOnState
                selectionCB.identifier = scriptToQuery
                selectionCB.setContentHuggingPriority(245, for: .horizontal)  // Making < 250, so it stretches out to fill empty space to it's right.
                
                // Download Status Image View
                var downloadStatusImgView:NSImageView
                if #available(OSX 10.12, *) {
                    downloadStatusImgView = NSImageView(image: NSImage(named: "greyQM")!)
                } else {
                    // Fallback on earlier versions
                    downloadStatusImgView = NSImageView()
                    downloadStatusImgView.image = NSImage(named: "greyQM")
                    downloadStatusImgView.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                }
                downloadStatusImgView.identifier = scriptToQuery
                downloadStatusImgViewDict[scriptToQuery] = downloadStatusImgView
                
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
                    downloadBtn.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                }
                downloadBtn.setButtonType(.toggle)
                downloadBtn.alternateTitle = NSLocalizedString("Cancel", comment: "cancel download button")
                downloadBtn.identifier = scriptToQuery
                downloadBtnDict[scriptToQuery] = downloadBtn
                
                // Download ImgBtn Stack View
                let downloadImgBtnSV = NSStackView()
                downloadImgBtnSV.spacing = 10
                downloadImgBtnSV.addView(downloadStatusImgView, in: .leading)
                downloadImgBtnSV.addView(downloadBtn, in: .leading)
                downloadImgBtnSV.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                
                // Download Progress
                let downloadProgressIndicator = NSProgressIndicator()
                downloadProgressIndicator.style = .barStyle
                downloadProgressIndicator.isIndeterminate = false
                downloadProgressIndicator.minValue = 0
                downloadProgressIndicator.maxValue = 100
                downloadProgressIndicator.doubleValue = 0
                downloadProgressIndicator.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                downloadProgressIndicatorDict[scriptToQuery] = downloadProgressIndicator
                
                // Download Stack View
                let downloadStackView = NSStackView()
                downloadStackView.orientation = .vertical
                downloadStackView.spacing = 0
                downloadStackView.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                downloadStackView.addView(downloadImgBtnSV, in: .top)
                downloadStackView.addView(downloadProgressIndicator, in: .top)
                
                // Set isDownloadingDict - just so we always have the Dict to work with
                isDownloadingDict[scriptToQuery] = false
                
                
                // Install Status Image View
                var installStatusImgView:NSImageView
                if #available(OSX 10.12, *) {
                    installStatusImgView = NSImageView(image: NSImage(named: "greyQM")!)
                } else {
                    // Fallback on earlier versions
                    installStatusImgView = NSImageView()
                    installStatusImgView.image = NSImage(named: "greyQM")
                    installStatusImgView.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                }
                installStatusImgView.identifier = scriptToQuery
                installStatusImgViewDict[scriptToQuery] = installStatusImgView
                
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
                    installBtn.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                }
                installBtn.identifier = scriptToQuery
                installBtnDict[scriptToQuery] = installBtn
                
                // Install ImgBtn Stack View
                let installImgBtnSV = NSStackView()
                installImgBtnSV.spacing = 10
                installImgBtnSV.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                installImgBtnSV.addView(installStatusImgView, in: .leading)
                installImgBtnSV.addView(installBtn, in: .leading)
                
                // Install Progress
                let installProgressIndicator = NSProgressIndicator()
                installProgressIndicator.style = .barStyle
                installProgressIndicator.isIndeterminate = false
                installProgressIndicator.minValue = 0
                installProgressIndicator.maxValue = 100
                installProgressIndicator.doubleValue = 0
                installProgressIndicator.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                installProgressIndicatorDict[scriptToQuery] = installProgressIndicator
                
                // Install Stack View
                let installStackView = NSStackView()
                installStackView.orientation = .vertical
                installStackView.spacing = 0
                installStackView.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                installStackView.addView(installImgBtnSV, in: .top)
                installStackView.addView(installProgressIndicator, in: .top)
                
                // Set isInstallingDict - just so we always have the Dict to work with
                isInstallingDict[scriptToQuery] = false
                
                
                // Create Entry StackView
                let entryStackView = NSStackView()  // Default is Horizontal
                entryStackView.alignment = .centerY
                entryStackView.spacing = 10
                entryStackView.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                
                
                // Add all our components to the entry stack view
                entryStackView.addView(selectionCB, in: .leading)
                entryStackView.addView(downloadStackView, in: .leading)
                entryStackView.addView(installStackView, in: .leading)
                
                // Add our entryStackView to the appsStackView
                appsStackView.addView(entryStackView, in: .top)
                
                // Re-center the window on the screen
                //self.view.window?.center()
            }
        }
        
        refreshAllGuiViews()
        
        performSegue(withIdentifier: "LanguageChooserVC", sender: self)
    }

    // MARK: IB Actions
    @IBAction func selectAllBtnToggled(_ sender: NSButton) {
        let newState = selectAllBtn.state
        
        for entryStackView in appsStackView.views as! [NSStackView] {
            if let selectionCB = entryStackView.views.first as! NSButton? {
                selectionCB.state = newState
            }
        }
    }
    
    
    @IBAction func quitBtnClicked(_ sender: NSButton) {
        NSApplication.shared().terminate(self)
    }
    
    @IBAction func downloadSelectedBtnClicked(_ sender: NSButton) {
        for entryStackView in appsStackView.views as! [NSStackView] {
            if let selectionCB = entryStackView.views.first as! NSButton?, let scriptToQuery = selectionCB.identifier, let downloadBtn = downloadBtnDict[scriptToQuery], let appMeta = appMetaDict[scriptToQuery] {
                if selectionCB.state == NSOnState && downloadBtn.state == NSOffState {
                    startDownloadTask(scriptToQuery: scriptToQuery, downloadUrl: appMeta.downloadUrl)
                    downloadBtn.state = NSOnState  // "Cancel"
                }
            }
        }
    }
    
    @IBAction func installSelectedBtnClicked(_ sender: NSButton) {
        // Collect all the "root" tasks - to run all at one time via AppleScript (so app asks user for PW just once)
        // All the "user" tasks can be kicked off as we come to them.
        
        var allInstallScriptsArr = [String]()
        
        for entryStackView in appsStackView.views as! [NSStackView] {
            if let selectionCB = entryStackView.views.first as! NSButton?, let scriptToQuery = selectionCB.identifier, let installBtn = installBtnDict[scriptToQuery], let appMeta = appMetaDict[scriptToQuery] {
                if selectionCB.state == NSOnState && installBtn.isEnabled {
                    isInstallingDict[scriptToQuery] = true
                    refreshAllGuiViews()
                    
                    if appMeta.installUser == "root" {
                        // Install as root - gather all together, then kick of 1 after this loop is done. (so user only enters PW once)
                        allInstallScriptsArr.append(scriptToQuery)
                    } else {
                        // Install as user - kick it off right now
                        _ = runAsyncTaskAsUser(scriptToQuery: scriptToQuery, arguments: ["-i", sourceFolder])
                    }
                }
            }
        }
        
        // Run as root, all the ones that need to be run as root.
        let allInstallScriptsStr = allInstallScriptsArr.joined(separator: " ")
        if allInstallScriptsStr != "" {
            runBgInstallsAsRoot(allInstallScriptsStr: allInstallScriptsStr)
        }
    }
    
    func downloadBtnClicked(btn: NSButton) {
        let scriptToQuery = btn.identifier ?? ""
        if !scriptToQuery.isEmpty {
            if let appMeta = appMetaDict[scriptToQuery] {
                if btn.state == NSOnState {
                    // === Start the download Task ===
                    startDownloadTask(scriptToQuery: scriptToQuery, downloadUrl: appMeta.downloadUrl)
                } else {
                    // === Cancel the download ===
                    urlSession.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) -> Void in
                        for downloadTask in downloadTasks {
                            if downloadTask.taskDescription == scriptToQuery {
                                self.printLog(str: "----------")
                                self.printLog(str: "Canceling Task: \(scriptToQuery)")
                                downloadTask.cancel()
                                self.isDownloadingDict[scriptToQuery] = false
                                self.refreshAllGuiViews()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func installBtnClicked(installBtn: NSButton) {
        let scriptToQuery = installBtn.identifier ?? ""
        if !scriptToQuery.isEmpty {
            isInstallingDict[scriptToQuery] = true
            refreshAllGuiViews()
            
            if let appMeta = appMetaDict[scriptToQuery] {
                if appMeta.installUser == "root" {
                    runBgInstallsAsRoot(allInstallScriptsStr: scriptToQuery)
                } else {
                    _ = runAsyncTaskAsUser(scriptToQuery: scriptToQuery, arguments: ["-i", sourceFolder])
                }
            }
        }
    }
    
    // MARK: Tasks
    func startDownloadTask(scriptToQuery: String, downloadUrl: URL) {
        self.printLog(str: "----------")
        self.printLog(str: "Starting Download: \(downloadUrl)")
        let urlRequest = URLRequest(url: downloadUrl)
        let downloadTask = urlSession.downloadTask(with: urlRequest)
        downloadTask.taskDescription = scriptToQuery
        downloadTask.resume()
        isDownloadingDict[scriptToQuery] = true
        refreshAllGuiViews()  // I think not necessary here, but won't hurt.
    }
    
    func runSyncTaskAsUser(scriptToQuery: String, arguments: [String]) -> String {
        // Note: Purposely running in Main thread because it's not going take that long to run each of our tasks
        
        printLog(str: "==========")
        printLog(str: "runSyncTaskAsUser: \(scriptToQuery) \(arguments[0]) ", terminator: "")  // Finish this print statement at end of runTask() function
        
        // Make sure we can find the script file. Return if not.
        let taskNameArr = scriptToQuery.components(separatedBy: ".")
        guard let path = Bundle.main.path(forResource: "Scripts/" + taskNameArr[0], ofType:taskNameArr[1]) else {
            printLog(str: "\n  Unable to locate: \(scriptToQuery)!")
            return "Unable to locate: \(scriptToQuery)!"
        }
        
        // Init outputPipe
        let outputPipe = Pipe()
        
        // Setup & Launch our process
        let ps: Process = Process()
        ps.launchPath = path
        ps.arguments = arguments
        ps.standardOutput = outputPipe
        ps.launch()
        ps.waitUntilExit()
        
        // Read everything the outputPipe captured from stdout
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        var outputString = String(data: data, encoding: String.Encoding.utf8) ?? ""
        outputString = outputString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Return the output
        printLog(str: "[output: \(outputString)]")
        return outputString
    }
    
    func runAsyncTaskAsUser(scriptToQuery: String, arguments: [String]) -> String {
        printLog(str: "==========")
        printLog(str: "runAsyncTaskAsUser: \(scriptToQuery) \(arguments[0])")
        
        // Setup & Launch our process Asynchronously
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        
        taskQueue.async {
            // Make sure we can find the script file. Return if not.
            let taskNameArr = scriptToQuery.components(separatedBy: ".")
            guard let path = Bundle.main.path(forResource: "Scripts/" + taskNameArr[0], ofType:taskNameArr[1]) else {
                self.printLog(str: "  Unable to locate: \(scriptToQuery)!")
                return
            }
            
            let ps: Process = Process()
            ps.launchPath = path
            ps.arguments = arguments
            ps.terminationHandler = {
                task in
                DispatchQueue.main.async(execute: {
                    if arguments[0] == "-i" {
                        self.isInstallingDict[scriptToQuery] = false
                        self.refreshAllGuiViews()
                    }
                })
            }
            
            // Init outputPipe
            let outputPipe = Pipe()
            ps.standardOutput = outputPipe
            
            ps.launch()
            ps.waitUntilExit()
            
            // Read everything the outputPipe captured from stdout
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            var outputString = String(data: data, encoding: String.Encoding.utf8) ?? ""
            outputString = outputString.trimmingCharacters(in: .whitespacesAndNewlines)
            
            self.printLog(str: "[output(\(scriptToQuery)): \(outputString)]")
        }
        
        return ""  // Return empty string if no errors
    }
    
    func runBgInstallsAsRoot(allInstallScriptsStr: String) {
        printLog(str: "=+=+=+=+=+")
        printLog(str: "runInstallsAsRoot()")

        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        
        taskQueue.async {
            // AppleScript
            let appleScriptStr = "do shell script \"./runIs.sh '\(self.sourceFolder)' \(allInstallScriptsStr)\" with administrator privileges"
            self.printLog(str: "appleScriptStr: \(appleScriptStr)")
            
            // Run AppleScript
            var asError: NSDictionary?
            if let asObject = NSAppleScript(source: appleScriptStr) {
                let asOutput: NSAppleEventDescriptor = asObject.executeAndReturnError(&asError)
                
                if let err = asError {
                    self.printLog(str: "AppleScript Error: \(err)")
                } else {
                    self.printLog(str: asOutput.stringValue ?? "Note!: AS Output has 'nil' for stringValue")
                }
                
                // For each of the scripts, say that we're done installing
                let allInstallScriptsArr = allInstallScriptsStr.components(separatedBy: " ")
                for scriptToQuery in allInstallScriptsArr {
                    self.isInstallingDict[scriptToQuery] = false
                }
                DispatchQueue.main.async(execute: {
                    self.refreshAllGuiViews()
                })
            }
            self.printLog(str: "=-=-=-=-=-")
        }
    }
    
    // MARK: Misc. Functions
    func refreshAllGuiViews() {
        for (scriptToQuery, downloadStatusImgView) in downloadStatusImgViewDict {
            if let appMeta = appMetaDict[scriptToQuery], let downloadProgressIndicator = downloadProgressIndicatorDict[scriptToQuery], let installStatusImgView = installStatusImgViewDict[scriptToQuery], let downloadBtn = downloadBtnDict[scriptToQuery], let installBtn = installBtnDict[scriptToQuery], let isDownloading = isDownloadingDict[scriptToQuery], let isInstalling = isInstallingDict[scriptToQuery] {
                
                // === Refresh All Download Views ===
                
                // Download Status ImageView
                let destinationURLForFile = URL(fileURLWithPath: "\(sourceFolder)/\(appMeta.saveAsFilename)")
                if FileManager.default.fileExists(atPath: destinationURLForFile.path) {
                    downloadStatusImgView.image = NSImage(named: "greenCheck")
                } else {
                    downloadStatusImgView.image = NSImage(named: "redX")
                }
                
                // Download Btn
                //  'Usually', automatically taken care of because it's a toggle button. But in case of download comleting, we need to programmatically toggle this button
                if isDownloading {
                    downloadBtn.state = NSOnState  // "Cancel"
                } else {
                    downloadBtn.state = NSOffState  // "Download"
                }
                
                // Download Progress Indicator
                if isDownloading {
                    // Automatically taken care of by task/session delegate
                } else {
                    downloadProgressIndicator.doubleValue = 0.0
                }
                
                
                // === Refresh All Install Views ===
                
                // Install Status ImageView
                var proofPathActuallyExists = false
                for proofPath in appMeta.proofAppExistsPaths {
                    if FileManager.default.fileExists(atPath: proofPath) {
                        proofPathActuallyExists = true
                        break
                    }
                }
                if proofPathActuallyExists {
                    installStatusImgView.image = NSImage(named: "greenCheck")
                } else {
                    installStatusImgView.image = NSImage(named: "redX")
                }
                
                // Install Btn
                if isInstalling || isDownloading || downloadStatusImgView.image?.name() == "redX" {
                    installBtn.isEnabled = false
                } else {
                    if installStatusImgView.image?.name() == "redX" {
                        installBtn.isEnabled = true
                    } else {
                        installBtn.isEnabled = enableInstallPreApps
                    }
                }
                
                // Install Progress Indicator
                if let isInstalling = isInstallingDict[scriptToQuery], let installProgressIndicator = installProgressIndicatorDict[scriptToQuery] {
                    if isInstalling {
                        // Start the indeterminate progress indicators
                        installProgressIndicator.isIndeterminate = true
                        installProgressIndicator.startAnimation(self)
                    } else {
                        // Stop the indeterminate progress indicators
                        installProgressIndicator.stopAnimation(self)
                        installProgressIndicator.isIndeterminate = false
                        installProgressIndicator.doubleValue = 0.0
                    }
                }
            }
        }
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
        guard let runIsPath = Bundle.main.path(forResource: "Scripts/runIs", ofType:"sh") else {
            printLog(str: "\n  Unable to locate: Scripts/runIs.sh!")
            return
        }
        
        scriptsDirPath = String(runIsPath.characters.dropLast(8))  // drop off: "runIs.sh"
        if FileManager.default.changeCurrentDirectoryPath(scriptsDirPath) {
            //printLog(str: "success changing dir to: \(scriptsDirPath)")
        } else {
            printLog(str: "failure changing dir to: \(scriptsDirPath)")
        }
    }
    
    func setupScriptsToQueryArray() {
        do {
            var scriptsDirContents = try FileManager.default.contentsOfDirectory(atPath: scriptsDirPath)
            
            // Remove "runIs.sh" from the list of scripts.
            if let index = scriptsDirContents.index(of: "runIs.sh") {
                scriptsDirContents.remove(at: index)
            }
            
            scriptsToQuery = scriptsDirContents
            printLog(str: "scriptsToQuery: \(scriptsToQuery)")
        } catch {
            printLog(str: "Cannot get contents of Scripts dir: \(scriptsDirPath)")
        }
    }
    
    func getCurrLangIso() -> String {
        let currLangArr = UserDefaults.standard.value(forKey: "AppleLanguages") as! [String]
        
        var currLangIso = currLangArr[0]
        
        // Chop off everything except 1st two characters
        currLangIso = currLangIso.substring(to: currLangIso.index(currLangIso.startIndex, offsetBy: 2))
        
        return currLangIso
    }
}


extension DownloadInstallVC: URLSessionDownloadDelegate {
    //MARK: URLSessionDownloadDelegate
    // 1
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // Download task DID finish successfully. Though, it MIGHT be HTML in case of 404 error, for example.
        
        //printLog(str: "=== Session DownloadTask DidFinishDownloadingTo: \(location)")
        
        if let scriptToQuery = downloadTask.taskDescription {
            if let appMeta = appMetaDict[scriptToQuery] {
                if let httpResponse = downloadTask.response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    printLog(str: "----------")
                    printLog(str: "HTTP Status Code: \(statusCode)")
                    if statusCode == 200 {
                        let destinationURLForFile = URL(fileURLWithPath: "\(sourceFolder)/\(appMeta.saveAsFilename)")
                        //printLog(str: "destUrlForFile: \(destinationURLForFile)")
                        printLog(str: "Download Successful! (\(appMeta.saveAsFilename))")
                        
                        // Remove existing file if exists at destination dir
                        if FileManager.default.fileExists(atPath: destinationURLForFile.path){
                            printLog(str: "File already exists at destination. Removing.")
                            do {
                                try FileManager.default.removeItem(at: destinationURLForFile)
                            }catch{
                                printLog(str: "  An error occurred while removing file")
                            }
                        }
                        
                        // Move item from temp dir to desination dir
                        printLog(str: "Moving download to: \(destinationURLForFile)")
                        do {
                            try FileManager.default.moveItem(at: location, to: destinationURLForFile)
                        }catch{
                            printLog(str: "  An error occurred while moving download to destination url")
                        }
                    } else {
                        printLog(str: "HTTP Response (Status Code) is not 200! Assuming Download Failure. Not copying file to destination url")
                    }
                } else {
                    printLog(str: "Unable to obtain HTTP Response! Assuming Download Failure. Not copying file to destination url")
                }

                isDownloadingDict[scriptToQuery] = false
                refreshAllGuiViews()
            }
        }
    }

    // 2
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64){
        
        if let scriptToQuery = downloadTask.taskDescription {
            if let downloadProgressIndicator = downloadProgressIndicatorDict[scriptToQuery] {
                downloadProgressIndicator.doubleValue = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
            }
        }
    }
    
    //MARK: URLSessionTaskDelegate
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?){
        // Any type of task is done, but MAYBE successfully, MAYBE with error.
        
        //printLog(str: "=== Session Task DidCompleteWithMAYBEError")
        
        if (error != nil) {
            printLog(str: "taskDidCompleteWithError: \(error!.localizedDescription)")
        }else{
            printLog(str: "The task finished transferring data successfully (any status code, even 404)")
        }
        
        if let scriptToQuery = task.taskDescription {
            isDownloadingDict[scriptToQuery] = false
            refreshAllGuiViews()
        }
    }
}
