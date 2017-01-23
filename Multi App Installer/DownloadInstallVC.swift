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
    var installUser: RunScriptAs
    var proofAppExistsPaths: [String]
}

enum RunScriptAs {
    case User
    case Root
}

enum RunScriptOnThread {
    case Main
    case Bg
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
    var downloadCurrVerLabelDict = [String : NSTextField]()
    var downloadBtnDict = [String : NSButton]()
    var downloadProgressIndicatorDict = [String : NSProgressIndicator]()
    var isDownloadingDict = [String : Bool]()
    
    var installStatusImgViewDict = [String : NSImageView]()
    var installCurrVerLabelDict = [String : NSTextField]()
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
        //Fn.printLog(str: "*viewDidAppear()*")
        
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
        Fn.printLog(str: "=====================")
        Fn.printLog(str: "[" + timestamp + "]")
        Fn.printLog(str: "=====================")
        
        Fn.printLog(str: "loadView()")
        super.loadView()
        
        if floor(NSAppKitVersionNumber) <= Double(NSAppKitVersionNumber10_9) {  // This check is necessary, because even in 10.12 loadView() is called.
            Fn.printLog(str: "  calling self.viewDidLoad() from loadView()")
            self.viewDidLoad() // call viewDidLoad (added in 10.10)
        }
    }
    
    override func viewDidLoad() {
        Fn.printLog(str: "viewDidLoad()")
        if #available(OSX 10.10, *) {
            Fn.printLog(str: "  super.viewDidLoad()")
            super.viewDidLoad()
        } else {
            Fn.printLog(str: "  NOT calling super.viewDidLoad() [because 10.9 or lower is being used.")
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
        
        let skipLangDB = UserDefaults.standard.bool(forKey: "SkipLanguageDialogBoxOnNextStartup")
        if !skipLangDB {
            // Show Language Dialog box
            performSegue(withIdentifier: "LanguageChooserVC", sender: self)
        }
        UserDefaults.standard.setValue(false, forKey: "SkipLanguageDialogBoxOnNextStartup")
        
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
        let outputHandler: ([String : String]) -> (Void) = { outputDict in
            for (script, output) in outputDict {
                if output != "" {
                    let appMetaArr = output.components(separatedBy: "||")
                    
                    // Sanity Checks
                    guard appMetaArr.count == 5 else {
                        Fn.printLog(str: "appMetaArr.count (\(appMetaArr.count)) is not equal to 5! Failing. Format for -appMeta is e.g.: desc||downloadUrl||saveAsFilename||installAsRootOrUser||proofPaths")
                        continue  // to next iteration of for loop
                    }
                    guard let downloadUrl = URL(string: appMetaArr[1]) else {
                        Fn.printLog(str: "ERROR: cannot create URL from this string: \(appMetaArr[1])")
                        continue  // to next iteration of for loop
                    }
                    guard appMetaArr[3] == "root" || appMetaArr[3] == "user" else {
                        Fn.printLog(str: "ERROR: appMeta[3] is not equal to 'root' or 'user'!")
                        continue  // to next iteration of for loop
                    }
                    
                    // Split proof paths, if there are more than 1.
                    let proofAppExistsPathsArr = appMetaArr[4].components(separatedBy: "|")
                    
                    // Add to dictionary
                    self.appMetaDict[script] = AppMeta(appDescription: appMetaArr[0], downloadUrl: downloadUrl, saveAsFilename: appMetaArr[2], installUser: appMetaArr[3] == "root" ? .Root : .User, proofAppExistsPaths: proofAppExistsPathsArr)
                }
            }
        }
        run(theseScripts: scriptsToQuery, withArgs: ["-appMeta \(Fn.getCurrLangIso())"], asUser: .User, onThread: .Main, withOutputHandler: outputHandler)
        
        for scriptToQuery in scriptsToQuery {
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
                
                // Download Img/Btn Stack View
                let downloadImgBtnSV = NSStackView()
                downloadImgBtnSV.spacing = 10
                downloadImgBtnSV.addView(downloadStatusImgView, in: .leading)
                downloadImgBtnSV.addView(downloadBtn, in: .leading)
                downloadImgBtnSV.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                
                // Download Current Version (note: don't use this now [at least not yet], but is here to keep spacing consistent)
                var downloadCurrVerLabel:NSTextField
                if #available(OSX 10.12, *) {
                    downloadCurrVerLabel = NSTextField(labelWithString: "")
                } else {
                    // Fallback on earlier versions
                    downloadCurrVerLabel = NSTextField()
                    downloadCurrVerLabel.stringValue = ""
                    downloadCurrVerLabel.isEditable = false
                    downloadCurrVerLabel.isSelectable = false
                    downloadCurrVerLabel.isBezeled = false
                    downloadCurrVerLabel.backgroundColor = NSColor.clear
                    downloadCurrVerLabel.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                }
                downloadCurrVerLabel.font = NSFont.systemFont(ofSize: 10.0)
                downloadCurrVerLabel.identifier = scriptToQuery
                downloadCurrVerLabelDict[scriptToQuery] = downloadCurrVerLabel
                
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
                downloadStackView.alignment = .leading
                downloadStackView.spacing = 0
                downloadStackView.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                downloadStackView.addView(downloadImgBtnSV, in: .top)
                downloadStackView.addView(downloadCurrVerLabel, in: .top)
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
                
                // Install Img/Btn Stack View
                let installImgBtnSV = NSStackView()
                installImgBtnSV.spacing = 10
                installImgBtnSV.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                installImgBtnSV.addView(installStatusImgView, in: .leading)
                installImgBtnSV.addView(installBtn, in: .leading)
                
                // Install Current Version
                var installCurrVerLabel:NSTextField
                if #available(OSX 10.12, *) {
                    installCurrVerLabel = NSTextField(labelWithString: "(?)")
                } else {
                    // Fallback on earlier versions
                    installCurrVerLabel = NSTextField()
                    installCurrVerLabel.stringValue = "(?)"
                    installCurrVerLabel.isEditable = false
                    installCurrVerLabel.isSelectable = false
                    installCurrVerLabel.isBezeled = false
                    installCurrVerLabel.backgroundColor = NSColor.clear
                    installCurrVerLabel.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                }
                installCurrVerLabel.font = NSFont.systemFont(ofSize: 10.0)
                installCurrVerLabel.identifier = scriptToQuery
                installCurrVerLabelDict[scriptToQuery] = installCurrVerLabel
                
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
                installStackView.alignment = .leading
                installStackView.spacing = 0
                installStackView.translatesAutoresizingMaskIntoConstraints = false  // NSStackView bug for 10.9 & 10.10
                installStackView.addView(installImgBtnSV, in: .top)
                installStackView.addView(installCurrVerLabel, in: .top)
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
        
        // Re-center the window on the screen
        self.view.window?.center()
    }

    // MARK: IB Actions
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
                                Fn.printLog(str: "----------")
                                Fn.printLog(str: "Canceling Task: \(scriptToQuery)")
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
                let outputHandler: ([String : String]) -> (Void) = { outputDict in
                    self.isInstallingDict[scriptToQuery] = false
                    DispatchQueue.main.async(execute: {
                        self.refreshAllGuiViews()
                    })
                }
                if appMeta.installUser == .Root {
                    run(theseScripts: [scriptToQuery], withArgs: ["-i \(sourceFolder)"], asUser: .Root, onThread: .Bg, withOutputHandler: outputHandler)
                } else {  // .Main
                    run(theseScripts: [scriptToQuery], withArgs: ["-i \(sourceFolder)"], asUser: .User, onThread: .Bg, withOutputHandler: outputHandler)
                }
            }
        }
    }
    
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
        
        var allScriptsToQueryAsRootArr = [String]()
        var allScriptsToQueryAsUserArr = [String]()
        
        for entryStackView in appsStackView.views as! [NSStackView] {
            if let selectionCB = entryStackView.views.first as! NSButton?, let scriptToQuery = selectionCB.identifier, let installBtn = installBtnDict[scriptToQuery], let appMeta = appMetaDict[scriptToQuery] {
                if selectionCB.state == NSOnState && installBtn.isEnabled {
                    isInstallingDict[scriptToQuery] = true
                    refreshAllGuiViews()
                    
                    if appMeta.installUser == .Root {
                        // Gather all together, then kick of 1 after this loop is done. (so user only enters PW once)
                        allScriptsToQueryAsRootArr.append(scriptToQuery)
                    } else {  // .User
                        allScriptsToQueryAsUserArr.append(scriptToQuery)
                    }
                }
            }
        }
        
        
        // Root - run root scripts first, so PW can be prompted for right away (don't have to wait for all User scripts to run & complete first.)
        if allScriptsToQueryAsRootArr.count > 0 {
            let outputHandler: ([String : String]) -> (Void) = { outputDict in
                //For each of the scripts, say that we're done installing
                for scriptToQuery in allScriptsToQueryAsRootArr {
                    self.isInstallingDict[scriptToQuery] = false
                }
                DispatchQueue.main.async(execute: {
                    self.refreshAllGuiViews()
                })
            }
            // Note: if there are 3 scripts (for example), outputHandler will not be called until all 3 are completely finished running. Must be this way if we only want to ask the user for Root PW one time.
            run(theseScripts: allScriptsToQueryAsRootArr, withArgs: ["-i \(sourceFolder)"], asUser: .Root, onThread: .Bg, withOutputHandler: outputHandler)
        }

        // User
        if allScriptsToQueryAsUserArr.count > 0 {
            // But run User scripts 1 at a time, so at least user can see some occasional progress on the GUI
            for scriptToQuery in allScriptsToQueryAsUserArr {
                let outputHandler: ([String : String]) -> (Void) = { outputDict in
                    // Say that we're done installing
                    self.isInstallingDict[scriptToQuery] = false
                    DispatchQueue.main.async(execute: {
                        self.refreshAllGuiViews()
                    })
                }
                run(theseScripts: [scriptToQuery], withArgs: ["-i \(sourceFolder)"], asUser: .User, onThread: .Bg, withOutputHandler: outputHandler)
            }
        }
    }
    
    // MARK: Download Task
    func startDownloadTask(scriptToQuery: String, downloadUrl: URL) {
        Fn.printLog(str: "----------")
        Fn.printLog(str: "Starting Download: \(downloadUrl)")
        let urlRequest = URLRequest(url: downloadUrl)
        let downloadTask = urlSession.downloadTask(with: urlRequest)
        downloadTask.taskDescription = scriptToQuery
        downloadTask.resume()
        isDownloadingDict[scriptToQuery] = true
        refreshAllGuiViews()  // I think not necessary here, but won't hurt.
    }
    
    // MARK: Run Scripts
    // Note: This is the function the code is expected to call when wanting to run/query any script(s)
    func run(theseScripts: [String], withArgs: [String], asUser: RunScriptAs, onThread: RunScriptOnThread, withOutputHandler: ((_ outputDict: [String : String]) -> Void)?) {
        Fn.printLog(str: "----------")
        Fn.printLog(str: "runScripts: \(theseScripts), withArgs: \(withArgs), asUser: \(asUser), onThread: \(onThread)")
        
        if onThread == .Bg {
            let taskQueue = DispatchQueue.global(qos: .userInitiated)
            taskQueue.async {
                self.run(theseScripts: theseScripts, withArgs: withArgs, asUser: asUser, withOutputHandler: withOutputHandler)
            }
        } else {  // .Main
            run(theseScripts: theseScripts, withArgs: withArgs, asUser: asUser, withOutputHandler: withOutputHandler)
        }
    }
    
    // Note: could call this function directly, but it's more clear if called from: run(theseScriptsWithArgsAsUserOnThreadWithOutputHandler)
    func run(theseScripts: [String], withArgs: [String], asUser: RunScriptAs, withOutputHandler: ((_ outputDict: [String : String]) -> Void)?) {
        // Write AppleScript
        let allScriptsStr = theseScripts.joined(separator: " ")
        let argsStr = withArgs.joined(separator: " ")
        var appleScriptStr = "do shell script \"./runScripts.sh '\(argsStr)' \(allScriptsStr)\""
        if asUser == .Root {
            appleScriptStr += " with administrator privileges"
        }
        Fn.printLog(str: " appleScriptStr: \(appleScriptStr)")
        
        if let asObject = NSAppleScript(source: appleScriptStr) {
            // Run AppleScript
            var asError: NSDictionary?
            //Fn.printLog(str: "**temp: right before AS call.")
            let asOutput: NSAppleEventDescriptor = asObject.executeAndReturnError(&asError)
            Fn.printLog(str: " [asOutput: \(asOutput.stringValue ?? "")]")
            
            // Parse & Handle AppleScript output
            let outputArr = self.parseAppleScript(asOutput: asOutput, asError: asError)
            handle(theseScripts: theseScripts, outputArr: outputArr, withOutputHandler: withOutputHandler)
        }
    }
    
    func parseAppleScript(asOutput: NSAppleEventDescriptor, asError: NSDictionary?) -> [String] {
        if let err = asError {
            Fn.printLog(str: "AppleScript Error: \(err)")
            return []
        } else {
            // First tidy-up str a bit
            if let asOutputRaw = asOutput.stringValue {
                var asOutputStr = asOutputRaw.replacingOccurrences(of: "\r\n", with: "\n") // just incase
                asOutputStr = asOutputStr.replacingOccurrences(of: "\r", with: "\n") // becasue AppleScript returns line endings with '\r'
                let asOutputArr = asOutputStr.components(separatedBy: "\n")
                return asOutputArr
            }
        }
        
        return [""]
    }
    
    func handle(theseScripts: [String], outputArr: [String], withOutputHandler: ((_ outputDict: [String : String]) -> Void)?) {
        if let outputHandler = withOutputHandler {
            var outputDict = [String : String]()
            
            guard outputArr.count == theseScripts.count else {
                Fn.printLog(str: "*ERROR: outputArray.count (\(outputArr.count)) is not equal to scripts.count (\(theseScripts.count))")
                Fn.printLog(str: "*  outputArr: \(outputArr)")
                outputHandler(outputDict)
                return
            }
            
            var idx = 0
            for script in theseScripts {
                outputDict[script] = outputArr[idx]
                idx += 1
            }
            
            outputHandler(outputDict)
        }
    }
    
    // MARK: Misc. Functions
    func refreshAllGuiViews() {
        for (scriptToQuery, downloadStatusImgView) in downloadStatusImgViewDict {
            if let appMeta = appMetaDict[scriptToQuery], let downloadProgressIndicator = downloadProgressIndicatorDict[scriptToQuery], let installStatusImgView = installStatusImgViewDict[scriptToQuery], let installCurrVerLabel = installCurrVerLabelDict[scriptToQuery], let downloadBtn = downloadBtnDict[scriptToQuery], let installBtn = installBtnDict[scriptToQuery], let isDownloading = isDownloadingDict[scriptToQuery], let isInstalling = isInstallingDict[scriptToQuery] {
                
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
                var actualExistingProofPath = ""
                for proofPath in appMeta.proofAppExistsPaths {
                    if FileManager.default.fileExists(atPath: proofPath) {
                        proofPathActuallyExists = true
                        actualExistingProofPath = proofPath  // to use for "version" below
                        break
                    }
                }
                if proofPathActuallyExists {
                    installStatusImgView.image = NSImage(named: "greenCheck")
                } else {
                    installStatusImgView.image = NSImage(named: "redX")
                }
                
                // Install Current Version Label
                if installStatusImgView.image?.name() == "greenCheck" {
                    var outputPipe: Pipe
                    let relPathToPlist = actualExistingProofPath.hasSuffix(".framework") ? "Resources/Info.plist" : "Contents/Info.plist"
                    outputPipe = runTask(cmd: "/usr/libexec/PlistBuddy", arguments: ["-c", "Print CFBundleShortVersionString", "\(actualExistingProofPath)/\(relPathToPlist)"], inputPipe: nil)
                    
                    let versionStr = getString(fromPipe: outputPipe)
                    installCurrVerLabel.stringValue = "(\(versionStr))"
                } else {
                    installCurrVerLabel.stringValue = ""
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
    
    func runTask(cmd: String, arguments: [String], inputPipe: Pipe?) -> Pipe {
        // Init outputPipe
        let outputPipe = Pipe()
        
        // Setup & Launch our process
        let ps: Process = Process()
        ps.launchPath = cmd
        ps.arguments = arguments
        ps.standardInput = inputPipe
        ps.standardOutput = outputPipe
        ps.launch()
        ps.waitUntilExit()

        return outputPipe
    }
    
    func getString(fromPipe: Pipe) -> String {
        let data = fromPipe.fileHandleForReading.readDataToEndOfFile()
        var outputString = String(data: data, encoding: String.Encoding.utf8) ?? ""
        outputString = outputString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Return the output
        return outputString
    }
    
    func changeCurrentDirToScriptsDir() {
        guard let runScriptsPath = Bundle.main.path(forResource: "Scripts/runScripts", ofType:"sh") else {
            Fn.printLog(str: "\n  Unable to locate: Scripts/runScripts.sh!")
            return
        }
        
        scriptsDirPath = String(runScriptsPath.characters.dropLast(13))  // drop off: "runScripts.sh"
        if FileManager.default.changeCurrentDirectoryPath(scriptsDirPath) {
            //Fn.printLog(str: "success changing dir to: \(scriptsDirPath)")
        } else {
            Fn.printLog(str: "failure changing dir to: \(scriptsDirPath)")
        }
    }
    
    func setupScriptsToQueryArray() {
        do {
            var scriptsDirContents = try FileManager.default.contentsOfDirectory(atPath: scriptsDirPath)
            
            // Remove "runScripts.sh" from the list of scripts.
            if let index = scriptsDirContents.index(of: "runScripts.sh") {
                scriptsDirContents.remove(at: index)
            }
            
            scriptsToQuery = scriptsDirContents
        } catch {
            Fn.printLog(str: "Cannot get contents of Scripts dir: \(scriptsDirPath)")
            scriptsToQuery = []
        }
    }
}


extension DownloadInstallVC: URLSessionDownloadDelegate {
    //MARK: URLSessionDownloadDelegate
    // 1
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // Download task DID finish successfully. Though, it MIGHT be HTML in case of 404 error, for example.
        
        //Fn.printLog(str: "=== Session DownloadTask DidFinishDownloadingTo: \(location)")
        
        if let scriptToQuery = downloadTask.taskDescription {
            if let appMeta = appMetaDict[scriptToQuery] {
                if let httpResponse = downloadTask.response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    Fn.printLog(str: "----------")
                    Fn.printLog(str: "HTTP Status Code: \(statusCode)")
                    if statusCode == 200 {
                        let destinationURLForFile = URL(fileURLWithPath: "\(sourceFolder)/\(appMeta.saveAsFilename)")
                        //Fn.printLog(str: "destUrlForFile: \(destinationURLForFile)")
                        Fn.printLog(str: "Download Successful! (\(appMeta.saveAsFilename))")
                        
                        // Remove existing file if exists at destination dir
                        if FileManager.default.fileExists(atPath: destinationURLForFile.path){
                            Fn.printLog(str: "File already exists at destination. Removing.")
                            do {
                                try FileManager.default.removeItem(at: destinationURLForFile)
                            }catch{
                                Fn.printLog(str: "  An error occurred while removing file")
                            }
                        }
                        
                        // Move item from temp dir to desination dir
                        Fn.printLog(str: "Moving download to: \(destinationURLForFile)")
                        do {
                            try FileManager.default.moveItem(at: location, to: destinationURLForFile)
                        }catch{
                            Fn.printLog(str: "  An error occurred while moving download to destination url")
                        }
                    } else {
                        Fn.printLog(str: "HTTP Response (Status Code) is not 200! Assuming Download Failure. Not copying file to destination url")
                    }
                } else {
                    Fn.printLog(str: "Unable to obtain HTTP Response! Assuming Download Failure. Not copying file to destination url")
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
        
        //Fn.printLog(str: "=== Session Task DidCompleteWithMAYBEError")
        
        if (error != nil) {
            Fn.printLog(str: "taskDidCompleteWithError: \(error!.localizedDescription)")
        }else{
            Fn.printLog(str: "The task finished transferring data successfully (any status code, even 404)")
        }
        
        if let scriptToQuery = task.taskDescription {
            isDownloadingDict[scriptToQuery] = false
            refreshAllGuiViews()
        }
    }
}
