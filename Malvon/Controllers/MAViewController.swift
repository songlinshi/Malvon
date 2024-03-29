//
//  MAViewController.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2021-11-29.
//  Copyright © 2021-2022 Ashwin Paudel. All rights reserved.
//

import Cocoa
import MABookmarksBar
import MASearchSuggestions
import MATabView
import MATools
import MAWebView
import WebKit

// The browser will have a slight delay when creating a new tab
// Default is 0.43 seconds
let waitTime = 0.43

// The number of items in the closed tabs list
let closeTabNumbers = 5

// If it should show the bookbars bar in the start page
let showsBookmarkOnlyInStartPage = false

// let processPool = WKProcessPool()

class MAViewController: NSViewController, MAWebViewDelegate, NSSearchFieldDelegate, MATabViewDelegate, MABookmarksBarDelegate {
    // MARK: - Elements

    let defaults = UserDefaults.standard

    @IBOutlet var bookmarksBar: MABookmarksBar!
    var AppConfigurations = AppProperties()
    
    // webView Element
    @IBOutlet var webTabView: MATabView!
    var webView: MAWebView?
    
    // Search Field and Progress Indicator Elements
    @IBOutlet var progressIndicator: NSProgressIndicator!
    @IBOutlet var searchField: MASearchField!
    
    // Refresh, Back, Forward outlets
    @IBOutlet var refreshButton: HoverButton!
    @IBOutlet var backButtonOutlet: HoverButton!
    @IBOutlet var forwardButtonOutlet: HoverButton!
    @IBOutlet var addNewTabButtonOutlet: HoverButton!
    
    // Search Suggestions field
    var suggestions = [String]()
    private var suggestionsController: MASuggestionsWindowController?
    private var skipNextSuggestion = false
    private var window = NSWindow()
    
    // For popups
    public var webConfigurations: WKWebViewConfiguration
    private var loadURL = true
    
    // The window properties
    public var windowController: MAWindowController
    
    // Just to improve proformance
    private var startPageHTML = String()
    let newtabURL = Bundle.main.url(forResource: "newtab", withExtension: "html")
    
    // Create a fixed size array ( saves memory )
    var lastOpenedTabs = [String](repeating: String(), count: closeTabNumbers)
    
    @IBOutlet var controlButtonBox: NSBox!
    
    var tabConfiguration: MATabViewConfiguration
    
    // MARK: - Setup Functions
    
    init(config: WKWebViewConfiguration = WKWebViewConfiguration(), loadURL: Bool = true, windowCNTRL: MAWindowController) {
        self.webConfigurations = config
//        webConfigurations.processPool = processPool
        
        self.tabConfiguration = MATabViewConfiguration()
        
        self.loadURL = loadURL
        self.windowController = windowCNTRL
        super.init(nibName: "MAViewController", bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        window = view.window!
        
        // Setup the buttons
        styleElements()
        searchField.alphaValue = 0.8
        searchField.layer?.borderWidth = 1
        searchField.layer?.cornerRadius = 8
        searchField.appearance = .init(named: .darkAqua)
    }
    
    override func viewDidLayout() {
        let appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        if appearance == "Dark" {
            controlButtonBox.fillColor = tabConfiguration.darkTabBackgroundColor
            view.layer?.backgroundColor = tabConfiguration.darkTabBackgroundColor.cgColor
            searchField.textColor = .white
        } else {
            controlButtonBox.fillColor = tabConfiguration.lightTabBackgroundColor
            view.layer?.backgroundColor = tabConfiguration.lightTabBackgroundColor.cgColor
            searchField.textColor = .black
        }
        
        if AppConfigurations.isEnergySaverModeOn {
            progressIndicator.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if defaults.bool(forKey: UserDefaultValues.isBookmarksBarVisible) {
            bookmarksBar.isHidden = false
        } else {
            bookmarksBar.isHidden = true
        }
        
        bookmarksBar.delegate = self
        loadBookmarksBar()
        webTabView.configuration = tabConfiguration
        view.wantsLayer = true
        
        // Remove the cancel and search buttons from the searchfield
        if let cell = searchField.cell as? NSSearchFieldCell {
            cell.searchButtonCell?.isTransparent = true
            cell.cancelButtonCell?.isTransparent = true
            cell.focusRingType = .none
        }
        
        DispatchQueue.global(qos: .background).async { [self] in
                if let string = UserDefaults.standard.string(forKey: UserDefaultValues.startHTMLPage) {
                    startPageHTML = string
                } else {
                    startPageHTML = MAURL(newtabURL!).contents()
                    UserDefaults.standard.set(startPageHTML, forKey: UserDefaultValues.startHTMLPage)
                }
                
                if let lastTabs = UserDefaults.standard.stringArray(forKey: UserDefaultValues.lastOpenedTabs) {
                    lastOpenedTabs = lastTabs
                } else {
                    lastOpenedTabs = [String]()
                    UserDefaults.standard.set(lastOpenedTabs, forKey: UserDefaultValues.lastOpenedTabs)
                }
        }
        
        // Add the `webView` to the `webTabView`
        webView = MAWebView(frame: webTabView.frame, configuration: webConfigurations)
        
        webView = getNewWebViewInstance(config: webConfigurations)
        webTabView.create(tab: MATab(view: webView!, title: "Untitled Tab"))
        webTabView.delegate = self
        webView?.configuration.websiteDataStore = .default()
        
        // Configure the elements
            configureElements()
            if loadURL {
                webView!.loadHTMLString(startPageHTML, baseURL: newtabURL!)
            }
        
            if AppConfigurations.hidesScreenElementsWhenNotActive {
                // When the app enters the background
                let nc = NotificationCenter.default
                nc.addObserver(self, selector: #selector(willEnterBackground), name: NSApplication.willResignActiveNotification, object: nil)
                nc.addObserver(self, selector: #selector(willBecomeActive), name: NSApplication.willBecomeActiveNotification, object: nil)
            }
    }
    
    @objc func willEnterBackground() {
        webTabView.isHidden = true
        webView?.isHidden = true
        searchField.isHidden = true
        refreshButton.isHidden = true
        backButtonOutlet.isHidden = true
        forwardButtonOutlet.isHidden = true
        addNewTabButtonOutlet.isHidden = true
    }
    
    @objc func willBecomeActive() {
        webTabView.isHidden = false
        webView?.isHidden = false
        searchField.isHidden = false
        refreshButton.isHidden = false
        backButtonOutlet.isHidden = false
        forwardButtonOutlet.isHidden = false
        addNewTabButtonOutlet.isHidden = false
    }
    
    // Style the elements ( buttons, searchfields )
    func styleElements() {
        progressIndicator.alphaValue = 0.7
    }
    
    // Configure the elements ( buttons, searchfields )
    func configureElements() {
        searchField.delegate = self
        webView!.delegate = self
        webView!.initializeWebView()
        webView!.enableConfigurations()
        webView!.enableAdblock()
    }
    
    // MARK: - Buttons
    
    @IBAction func backButton(_ sender: Any) {
        // If the webView can go back, go back
        if webView!.canGoBack { webView!.goBack() }
    }
    
    @IBAction func forwardButton(_ sender: Any) {
        // If the webView can go forward, go forward
        if webView!.canGoForward { webView!.goForward() }
    }
    
    @IBAction func reloadWebpage(_ sender: Any) {
        webView!.reload()
    }
    
    @IBAction func refreshButton(_ sender: NSButton) {
        // If there is a reload icon, reload the page and display the X icon
        if sender.image == NSImage(named: NSImage.refreshTemplateName) {
            webView!.reload()
            sender.image = NSImage(named: NSImage.stopProgressTemplateName)
            // If there is a X icon, stop the webpage from loading
        } else if sender.image == NSImage(named: NSImage.stopProgressTemplateName) {
            webView!.stopLoading()
            sender.image = NSImage(named: NSImage.refreshTemplateName)
        }
    }
    
    func createNewTab(url: URL) {
        // Create a new tab
        webView = getNewWebViewInstance(url: url)
        
        Timer.scheduledTimer(withTimeInterval: waitTime, repeats: false) { [self] _ in
            webTabView.create(tab: MATab(view: self.webView!, title: "Untitled Tab"))
            
            if !(AppConfigurations.isEnergySaverModeOn) {
                webTabView.set(tab: webTabView.selectedTab!.position, icon: getFavicon(url: self.webView!.url!.absoluteString) ?? NSImage())
            }
            
            webTabView.set(tab: webTabView.selectedTab!.position, title: self.webView!.title ?? "Untitled Tab")
            
            self.webView?.delegate = self
        }
    }
    
    func createNewTab() {
        // Create a new tab
        webView = getNewWebViewInstance()
        
        Timer.scheduledTimer(withTimeInterval: waitTime, repeats: false) { [self] _ in
            webTabView.create(tab: MATab(view: self.webView!, title: "Untitled Tab"))
            
            if !(AppConfigurations.isEnergySaverModeOn) {
                webTabView.set(tab: webTabView.selectedTab!.position, icon: getFavicon(url: self.webView!.url!.absoluteString) ?? NSImage())
            }
            
            webTabView.set(tab: webTabView.selectedTab!.position, title: self.webView!.title ?? "Untitled Tab")
            
            self.webView?.delegate = self
        }
    }
    
    @IBAction func createNewTab(_ sender: Any) {
        // Create a new tab
        if NSApp.windows.isEmpty {
            let newWindow = MAWindowController(windowNibName: "MAWindowController")
            newWindow.showWindow(nil)
        }
        webView = getNewWebViewInstance()
        Timer.scheduledTimer(withTimeInterval: waitTime, repeats: false) { [self] _ in
            webTabView.create(tab: MATab(view: self.webView!, title: "Untitled Tab"))
            
            if !(AppConfigurations.isEnergySaverModeOn) {
                webTabView.set(tab: webTabView.selectedTab!.position, icon: getFavicon(url: self.webView!.url!.absoluteString) ?? NSImage())
            }
            webTabView.set(tab: webTabView.selectedTab!.position, title: self.webView!.title ?? "Untitled Tab")
            
            self.webView?.delegate = self
        }
    }
    
    @IBAction func closeTab(_ sender: Any) {
        // Close the current tab
        webTabView.remove(tab: webTabView.selectedTab!)
    }
    
    @IBAction func reopenLastTab(_ sender: Any) {
        if !(lastOpenedTabs.isEmpty) {
            if let first = lastOpenedTabs.first {
                createNewTab(url: URL(string: first)!)
                lastOpenedTabs.removeFirst()
            }
        }
    }
    
    func checkButtons() {
        if !(AppConfigurations.isEnergySaverModeOn) {
            if let webView = webView {
                // If the webView can go back, enable the back button
                webView.canGoBack ? (backButtonOutlet.isEnabled = true) : (backButtonOutlet.isEnabled = false)
            
                // If the webView can go forward, enable the back forward
                webView.canGoForward ? (forwardButtonOutlet.isEnabled = true) : (forwardButtonOutlet.isEnabled = false)
            
                webView.isLoading ? (refreshButton.image = NSImage(named: NSImage.stopProgressTemplateName)) : (refreshButton.image = NSImage(named: NSImage.refreshTemplateName))
            }
        }
    }
    
    // MARK: - History Functions
    
    func parseHistoryJSON() -> [MAHistoryElement]? {
        // Read the file
        let fileContents = MAFile(path: MAHistoryViewController.path!).read()
        
        // Decode the file
        let decodedJSON = try? JSONDecoder().decode([MAHistoryElement].self, from: fileContents.data(using: .utf8)!)
        
        // Return the decoded JSON
        return decodedJSON
    }
    
    func addItem(website: String, address: String) {
        // If the history.json file doesn't exist, create an empty file
        createHistoryFileIfNotExists()
        
        // Create a new JSON Property
        var newHistoryJSON: [MAHistoryElement] = parseHistoryJSON()!
        
        // Add a new item to the new JSON property
        newHistoryJSON.append(MAHistoryElement(website: website, address: address))
        
        // Write the new JSON property
        DispatchQueue(label: "Malvon History").async {
            do {
                let data = try JSONEncoder().encode(newHistoryJSON)
                try data.write(to: MAHistoryViewController.path!)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // If the history.json file doesn't exist, create it
    func createHistoryFileIfNotExists() {
        let pathComponent = MAFile(path: MAHistoryViewController.path!)
        if !pathComponent.exists() {
            pathComponent.write("[]")
        }
    }
    
    // MARK: - webView Functions
    
    func mubWebView(_ webView: MAWebView, failedLoadingWebpage error: Error) {
        let newtabURL = Bundle.main.url(forResource: "error_page", withExtension: "html")
        self.webView!.loadFileURL(newtabURL!, allowingReadAccessTo: newtabURL!)
        
        if let info = error._userInfo as? [String: Any] {
            if let url = info["NSErrorFailingURLKey"] as? URL {
                let errorMessageScript = WKUserScript(source: "errorMessage(\"\(error.localizedDescription)\")\nlet retryLoadingURL = \"\(url.absoluteString)\"", injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                webView.configuration.userContentController.addUserScript(errorMessageScript)
            }
        }
    }
    
    func mubWebView(_ webView: MAWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        // Create the file panel
        let dialog = NSOpenPanel()
        
        // Configure the NSOpenPanel
        dialog.allowsMultipleSelection = parameters.allowsMultipleSelection
        dialog.canChooseDirectories = parameters.allowsDirectories
        
        // Show the file panel
        dialog.beginSheetModal(for: view.window!) { result in
            // If the user uploads a file complete
            if result == .OK {
                if let url = dialog.url {
                    // Upload the file url to the webpage
                    completionHandler([url])
                }
            } else {
                // If the user clicks cancle
                self.complete(nil)
            }
        }
    }
    
    func updateColors(colorConfig: MATabViewConfiguration) {
        let appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        
        if appearance == "Dark" {
            controlButtonBox.fillColor = colorConfig.darkTabBackgroundColor
            view.layer?.backgroundColor = colorConfig.darkTabBackgroundColor.cgColor
        } else {
            controlButtonBox.fillColor = colorConfig.lightTabBackgroundColor
            view.layer?.backgroundColor = colorConfig.lightTabBackgroundColor.cgColor
        }
                
        // Update the webview elements
        if !tabConfiguration.lightTabBackgroundColor.isLight {
            backButtonOutlet.contentTintColor = .white
            forwardButtonOutlet.contentTintColor = .white
            refreshButton.contentTintColor = .white
            addNewTabButtonOutlet.contentTintColor = .white
            tabConfiguration.darkTabBorderColor = .white
            tabConfiguration.lightTabBorderColor = .white
            tabConfiguration.lightTabTitleTextColor = .white
            tabConfiguration.darkTabTitleTextColor = .white
            searchField.textColor = .white
            searchField.layer?.borderColor = NSColor.white.cgColor
            bookmarksBar.updateColors(background: tabConfiguration.darkTabBackgroundColor, titleColor: .white)
            suggestionsController?.updateColors(backgroundColor: tabConfiguration.darkTabColor, highlightColor: .controlAccentColor, textColor: .white)
        } else {
            backButtonOutlet.contentTintColor = .black
            forwardButtonOutlet.contentTintColor = .black
            refreshButton.contentTintColor = .black
            addNewTabButtonOutlet.contentTintColor = .black
            tabConfiguration.darkTabBorderColor = .gray
            tabConfiguration.lightTabBorderColor = .gray
            tabConfiguration.lightTabTitleTextColor = .white
            tabConfiguration.darkTabTitleTextColor = .white
            searchField.textColor = .black
            searchField.layer?.borderColor = NSColor.gray.cgColor
            suggestionsController?.updateColors(backgroundColor: tabConfiguration.darkTabBackgroundColor, highlightColor: .controlAccentColor, textColor: .black)
            bookmarksBar.updateColors(background: tabConfiguration.lightTabColor, titleColor: .white)
        }
        
        webTabView.updateColors(configuration: tabConfiguration)
    }
    
    func updateThemeColor(colorConfig: MATabViewConfiguration) {
        // We must add a timer, otherwise it would look bad since it's rendering the webview and the background color
        
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [self] _ in
            let javascript = #"""
                    function a() {
                        var theme = document.querySelector("meta[name=theme-color]");
                        if (theme) {
                            return theme.content;
                        } else {
                            return window.getComputedStyle(document.body).backgroundColor;
                        }
                    };
                    a();
            """#
            
            webView!.evaluateJavaScript(javascript) { [self] value, _ in
                if let value = value {
                    let hexValue = value as! String
                    var color = NSColor.red
                    if hexValue.starts(with: "rgb") {
                        let colors = hexValue.stringAfter("(").stringBefore(")")
                        let colorValues = colors.components(separatedBy: ",")
                        var alpha = 1.0
                        if colorValues.count == 2 {
                            alpha = CGFloat(Float(colorValues[3])!)
                        }
                        
                        color = NSColor(
                            red: CGFloat(Float(colorValues[0].removeWhitespace)!),
                            green: CGFloat(Float(colorValues[1].removeWhitespace)!),
                            blue: CGFloat(Float(colorValues[2].removeWhitespace)!),
                            alpha: alpha
                        )
                    } else {
                        color = NSColor(hex: hexValue)
                    }
                    
                    colorConfig.lightTabBackgroundColor = color
                    colorConfig.darkTabColor = color.lighter()
                    colorConfig.lightTabColor = color.darker()
                    
                    colorConfig.darkTabBackgroundColor = color
                    updateColors(colorConfig: colorConfig)
                } else {
                    let blankColorConfig = MATabViewConfiguration()
                    updateColors(colorConfig: blankColorConfig)
                }
                print("THEME COLOR = \(value ?? "UNKNOWN")")
            }
        }
    }
    
    func mubWebView(_ webView: MAWebView, urlDidChange url: URL?) {
        if showsBookmarkOnlyInStartPage {
            bookmarksBar.isHidden = true
        }
        // Update the search field URL
        updateWebsiteURL()
        
        if !(AppConfigurations.isEnergySaverModeOn) {
            // Update the theme color
            updateThemeColor(colorConfig: tabConfiguration)
            // Check if we should enable one of the buttons
            checkButtons()
        }
    }
    
    func getFavicon(url: String) -> NSImage? {
        let url = URL(string: "https://www.google.com/s2/favicons?sz=30&domain_url=" + url)
        
        do {
            return NSImage(data: try Data(contentsOf: url!))
        } catch {}
        
        return nil
    }
    
    func mubWebView(_ webView: MAWebView, titleChanged title: String) {
        if let webView = webTabView.selectedTab?.view as? MAWebView {
            // Set the new title
            webTabView.set(tab: webTabView.selectedTab!.position, title: self.webView!.title ?? "Untitled Tab")
            
            if !(AppConfigurations.isEnergySaverModeOn) {
                // Get the favicon of the website
                guard let webViewURL = webView.url?.absoluteString else { return }
            
                webTabView.set(tab: webTabView.selectedTab!.position, icon: getFavicon(url: webViewURL) ?? NSImage())
            }
        }
    }
    
    func mubWebView(_ webView: MAWebView, createWebViewWith configuration: WKWebViewConfiguration, navigationAction: WKNavigationAction) -> MAWebView? {
        // Create a new tab and open it
        
        let newWebView = getNewWebViewInstance(config: configuration)
        
        Timer.scheduledTimer(withTimeInterval: waitTime, repeats: false) { [self] _ in
            webTabView.create(tab: MATab(view: newWebView, title: "Untitled Tab"))
            
            if !(AppConfigurations.isEnergySaverModeOn) {
                webTabView.set(tab: webTabView.selectedTab!.position, icon: getFavicon(url: self.webView!.url?.absoluteString ?? "about:blank") ?? NSImage())
            }
            
            webTabView.set(tab: webTabView.selectedTab!.position, title: self.webView!.title ?? "Untitled Tab")
            
            self.webView = newWebView
            self.webView?.delegate = self
        }
        
        // Return the new tab's webView
        return newWebView
    }
    
    func mubWebView(_ webView: MAWebView, estimatedProgress progress: Double) {
        if !(AppConfigurations.isEnergySaverModeOn) {
            // Make the progress indicator visible
            progressIndicator.isHidden = false
        
            // Change the refresh button's icon to X mark
            refreshButton.image = NSImage(named: NSImage.stopProgressTemplateName)
        
            // Set the value of the progress indicator
            progressIndicator.doubleValue = (progress * 100)
        
            // Increase the value by 50
            progressIndicator.increment(by: 50)
        
            // Set it to use threaded animations
            progressIndicator.usesThreadedAnimation = true
        
            if progressIndicator.doubleValue == 100 {
                // Set the value to 0
                progressIndicator.doubleValue = 0
                // Hide the progress indicator
                progressIndicator.isHidden = true
                // Change the icon of the refresh button to the refresh icon
                refreshButton.image = NSImage(named: NSImage.refreshTemplateName)
                // Check if we should disable or enable any buttons
                checkButtons()
            }
        }
    }
    
    func mubWebViewWillCloseTab() {
        webTabView.remove(tab: webTabView.selectedTab!)
    }
    
    func updateWebsiteURL() {
        if !(AppConfigurations.isEnergySaverModeOn) {
            // Highlight the searchfield value
            guard let url = webView!.url else { return }
        
            let attribute = [NSAttributedString.Key.foregroundColor: NSColor.gray]
        
            if url.scheme == "file" {
                if url.absoluteString.starts(with: Bundle.main.bundleURL.absoluteString) == true {
                    let attrScheme = NSMutableAttributedString(string: "malvon?", attributes: attribute)
                    let attrHost = NSAttributedString(string: url.absoluteString.fileName)
                    if url.absoluteString.fileName == "newtab" {
                        // Set the search field to nothing so that the user can type
                        searchField.stringValue = ""
                        return
                    }
                
                    attrScheme.append(attrHost)
                    searchField.attributedStringValue = attrScheme
                } else {
                    searchField.stringValue = url.absoluteString
                }
            } else {
                let scheme = (url.scheme ?? "") + "://"
                let host = url.host ?? ""
                var path = url.path
                let query = url.query ?? ""
            
                query.isEmpty ? () : (path += "?" + query)
            
                let attrPath = NSAttributedString(string: path, attributes: attribute)
                let attrHost = NSAttributedString(string: host)
                let attrScheme = NSMutableAttributedString(string: scheme, attributes: attribute)
            
                attrScheme.append(attrHost)
                attrScheme.append(attrPath)
            
                searchField.attributedStringValue = attrScheme
            }
        } else {
            searchField.stringValue = webView!.url!.absoluteString
        }
    }
    
    func mubWebView(_ webView: MAWebView, didFinishLoading url: URL?) {
        // Update the state of the back and forward buttons
        checkButtons()
        // Update the theme color
        if !(AppConfigurations.isEnergySaverModeOn) {
            let colorConfig = webTabView.tabBar.get(tabItem: webTabView.selectedTab!.position).configuration
            updateThemeColor(colorConfig: colorConfig)
            // Add a new item into the history
            addItem(website: webView.title!, address: webView.url!.absoluteString)
        }
    }
    
    // MARK: - Search Field
    
    @IBAction func searchFieldAction(_ sender: Any) {
        if searchField.stringValue.isEmpty {
            // Do nothing
            return
        } else if searchField.stringValue.starts(with: "malvon?") {
            guard let URL = Bundle.main.url(forResource: searchField.stringValue.string("malvon?"), withExtension: "html") else { return }
            webView!.loadFileURL(URL, allowingReadAccessTo: URL)
            
            // If the URL starts with 'file'
        } else if URL(string: searchField.stringValue)?.scheme == "file" {
            webView!.loadFileURL(URL(string: searchField.stringValue)!, allowingReadAccessTo: URL(string: searchField.stringValue)!)
            
            // If the URL is a valid URL
        } else if searchField.stringValue.isValidURL, !searchField.stringValue.containsWhitespace {
            webView!.load(URLRequest(url: MAURL(URL(string: searchField.stringValue)!).fix()))
            
            // If it's none of the above
        } else {
            webView!.load(URLRequest(url: URL(string: "https://www.google.com/search?client=Malvon&q=\(searchField.stringValue.encodeToURL)")!))
        }
    }
    
    @IBAction func searchFieldValueDidUpdate(_ sender: Any) {
        let entry = (sender as? MASuggestionsWindowController)?.selectedSuggestion()
        if entry != nil, !entry!.isEmpty {
            let fieldEditor: NSText? = window.fieldEditor(false, for: searchField)
            if fieldEditor != nil {
                updateFieldEditor(fieldEditor, withSuggestion: entry![kSuggestionLabel] as? String)
            }
        }
    }
    
    func suggestions(forText text: String?) -> [[String: Any]]? {
        SearchSuggestions.getQuerySuggestions(text!) { [unowned self] suggestions, error in
            if let suggestions = suggestions, suggestions.count > 0 {
                self.suggestions = suggestions
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        
        var suggestions = [[String: Any]]()
        suggestions.reserveCapacity(1)
        
        for val in self.suggestions {
            if text != nil, text != "", val.hasPrefix(text ?? "") || val.uppercased().hasPrefix(text?.uppercased() ?? "") {
                let entry: [String: Any] = [
                    kSuggestionLabel: val
                ]
                suggestions.append(entry)
            }
        }
        return suggestions
    }
    
    private func updateFieldEditor(_ fieldEditor: NSText?, withSuggestion suggestion: String?) {
        let selection = NSRange(location: fieldEditor?.selectedRange.location ?? 0, length: suggestion?.count ?? 0)
        fieldEditor?.string = suggestion ?? ""
        fieldEditor?.selectedRange = selection
    }
    
    /* Determines the current list of suggestions, display the suggestions and update the field editor.
     */
    func updateSuggestions(from control: NSControl?) {
        let fieldEditor: NSText? = window.fieldEditor(false, for: control)
        if fieldEditor != nil {
            // Only use the text up to the caret position
            let selection: NSRange? = fieldEditor?.selectedRange
            let text = (selection != nil) ? (fieldEditor?.string as NSString?)?.substring(to: selection!.location) : nil
            let suggestions = self.suggestions(forText: text)
            if suggestions != nil, suggestions!.count > 0 {
                // We have at least 1 suggestion. Update the field editor to the first suggestion and show the suggestions window.
                let suggestion = suggestions![0]
                
                updateFieldEditor(fieldEditor, withSuggestion: suggestion[kSuggestionLabel] as? String)
                suggestionsController?.setSuggestions(suggestions!)
                if !(suggestionsController?.window?.isVisible ?? false) {
                    suggestionsController?.begin(for: control as? NSSearchField)
                }
            } else {
                suggestionsController?.cancelSuggestions()
            }
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if !(AppConfigurations.isEnergySaverModeOn) {
            if !skipNextSuggestion {
                updateSuggestions(from: obj.object as? NSControl)
            } else {
                // If the suggestionController is already in a cancelled state, this call does nothing and is therefore always safe to call.
                suggestionsController?.cancelSuggestions()
                // This suggestion has been skipped, don"t skip the next one.
                skipNextSuggestion = false
            }
        }
        searchField.alphaValue = 1
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if !(AppConfigurations.isEnergySaverModeOn) {
            suggestionsController?.cancelSuggestions()
        }
        searchField.alphaValue = 0.8
    }
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        if !(AppConfigurations.isEnergySaverModeOn) {
            if !skipNextSuggestion {
                // We keep the suggestionsController around, but lazely allocate it the first time it is needed.
                if suggestionsController == nil {
                    suggestionsController = MASuggestionsWindowController()
                    suggestionsController?.target = self
                    suggestionsController?.action = #selector(searchFieldValueDidUpdate(_:))
                }
                updateSuggestions(from: obj.object as? NSControl)
            }
        }
    }
    
    /* As the delegate for the NSTextField, this class is given a chance to respond to the key binding commands interpreted by the input manager when the field editor calls -interpretKeyEvents:. This is where we forward some of the keyboard commands to the suggestion window to facilitate keyboard navigation. Also, this is where we can determine when the user deletes and where we can prevent AppKit"s auto completion.
     */
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if !(AppConfigurations.isEnergySaverModeOn) {
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                // Move up in the suggested selections list
                suggestionsController?.moveUp(textView)
                return true
            }
            if commandSelector == #selector(NSResponder.moveDown(_:)) {
                // Move down in the suggested selections list
                suggestionsController?.moveDown(textView)
                return true
            }
            if commandSelector == #selector(NSResponder.deleteForward(_:)) || commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                /* The user is deleting the highlighted portion of the suggestion or more. Return NO so that the field editor performs the deletion. The field editor will then call -controlTextDidChange:. We don"t want to provide a new set of suggestions as that will put back the characters the user just deleted. Instead, set skipNextSuggestion to YES which will cause -controlTextDidChange: to cancel the suggestions window. (see -controlTextDidChange: above)
                 */
                let insertionRange = textView.selectedRanges[0].rangeValue
                if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                    skipNextSuggestion = (insertionRange.location != 0 || insertionRange.length > 0)
                } else {
                    skipNextSuggestion = (insertionRange.location != textView.string.count || insertionRange.length > 0)
                }
                return false
            }
            if commandSelector == #selector(NSResponder.complete(_:)) {
                // The user has pressed the key combination for auto completion. AppKit has a built in auto completion. By overriding this command we prevent AppKit"s auto completion and can respond to the user"s intention by showing or cancelling our custom suggestions window.
                if suggestionsController != nil, suggestionsController!.window != nil, suggestionsController!.window!.isVisible {
                    suggestionsController?.cancelSuggestions()
                } else {
                    updateSuggestions(from: control)
                }
                return true
            }
        }
        // This is a command that we don't specifically handle, let the field editor do the appropriate thing.
        return false
    }
    
    // MARK: - Tab Menu Items
    
    func switchTo(tab number: Int, _ pauses: Bool = false, closes: Bool = false) {
        if !closes {
            if number <= webTabView.tabs.count - 1 {
                if pauses {
                    // Run the Javascript that will pause the video
                    let stopVideoScript = "var videos = document.getElementsByTagName('video'); for( var i = 0; i < videos.length; i++ ){videos.item(i).pause()}"
                    
                    // Tell the webview to run that javascript
                    webView!.evaluateJavaScript(stopVideoScript, completionHandler: nil)
                }
                
                // Change the current tab to the new number
                webTabView.select(tab: number)
            }
        } else {
            webTabView.remove(tab: number)
        }
    }
    
    @IBAction func tab1(_ sender: Any?) {
        switchTo(tab: 0)
    }
    
    @IBAction func tab2(_ sender: Any?) {
        switchTo(tab: 1)
    }
    
    @IBAction func tab3(_ sender: Any?) {
        switchTo(tab: 2)
    }
    
    @IBAction func tab4(_ sender: Any?) {
        switchTo(tab: 3)
    }
    
    @IBAction func tab5(_ sender: Any?) {
        switchTo(tab: 4)
    }
    
    @IBAction func tab6(_ sender: Any?) {
        switchTo(tab: 5)
    }
    
    @IBAction func tab7(_ sender: Any?) {
        switchTo(tab: 6)
    }
    
    @IBAction func tab8(_ sender: Any?) {
        switchTo(tab: 7)
    }
    
    @IBAction func tab9(_ sender: Any?) {
        switchTo(tab: 8)
    }
    
    @IBAction func tab1PAUSE(_ sender: Any?) {
        switchTo(tab: 0, true)
    }
    
    @IBAction func tab2PAUSE(_ sender: Any?) {
        switchTo(tab: 1, true)
    }
    
    @IBAction func tab3PAUSE(_ sender: Any?) {
        switchTo(tab: 2, true)
    }
    
    @IBAction func tab4PAUSE(_ sender: Any?) {
        switchTo(tab: 3, true)
    }
    
    @IBAction func tab5PAUSE(_ sender: Any?) {
        switchTo(tab: 4, true)
    }
    
    @IBAction func tab6PAUSE(_ sender: Any?) {
        switchTo(tab: 5, true)
    }
    
    @IBAction func tab7PAUSE(_ sender: Any?) {
        switchTo(tab: 6, true)
    }
    
    @IBAction func tab8PAUSE(_ sender: Any?) {
        switchTo(tab: 7, true)
    }
    
    @IBAction func tab9PAUSE(_ sender: Any?) {
        switchTo(tab: 8, true)
    }
    
    @IBAction func tab1CLOSE(_ sender: Any?) {
        switchTo(tab: 0, closes: true)
    }
    
    @IBAction func tab2CLOSE(_ sender: Any?) {
        switchTo(tab: 1, closes: true)
    }
    
    @IBAction func tab3CLOSE(_ sender: Any?) {
        switchTo(tab: 2, closes: true)
    }
    
    @IBAction func tab4CLOSE(_ sender: Any?) {
        switchTo(tab: 3, closes: true)
    }
    
    @IBAction func tab5CLOSE(_ sender: Any?) {
        switchTo(tab: 4, closes: true)
    }
    
    @IBAction func tab6CLOSE(_ sender: Any?) {
        switchTo(tab: 5, closes: true)
    }
    
    @IBAction func tab7CLOSE(_ sender: Any?) {
        switchTo(tab: 6, closes: true)
    }
    
    @IBAction func tab8CLOSE(_ sender: Any?) {
        switchTo(tab: 7, closes: true)
    }
    
    @IBAction func tab9CLOSE(_ sender: Any?) {
        switchTo(tab: 8, closes: true)
    }
    
    // MARK: - Tab Functions
    
    func tabView(_ tabView: MATabView, didSelect tab: MATab, colorConfig: MATabViewConfiguration) {
        webView = webTabView.selectedTab?.view as? MAWebView
        view.window?.makeFirstResponder(webView!)
        
        checkButtons()
        updateWebsiteURL()
        
        if !(AppConfigurations.isEnergySaverModeOn) {
            // Hide the progress indicator
            progressIndicator.isHidden = true
        }
        
        if !(AppConfigurations.isEnergySaverModeOn) {
            tabConfiguration = MATabViewConfiguration()
        
            updateThemeColor(colorConfig: tabConfiguration)
        }
    }
    
    func tabView(_ tabView: MATabView, didCreateTab tab: MATab) {
        if !(AppConfigurations.isEnergySaverModeOn) {
            progressIndicator.isHidden = true
        }
        if showsBookmarkOnlyInStartPage {
            bookmarksBar.isHidden = false
        }
        view.window?.makeFirstResponder(searchField)
    }
    
    func tabView(noMoreTabsLeft tabView: MATabView) {
        webView?.loadHTMLString("", baseURL: nil)
        
        if webView!.isObserving {
            // Hide progress indicator
            progressIndicator.isHidden = true
            // Stop it from loading
            webView?.stopLoading()
            // Remove all the observers on the webview
            webView?.removeWebview()
            // Remove from the superview
            webView?.removeFromSuperview()
            // Make it nil
            webView = nil
        }
        
        // Close the window
        view.window?.close()
    }
    
    func tabView(_ tabView: MATabView, willClose tab: MATab) {
        var tabWebView = webTabView.selectedTab?.view as? MAWebView
        
        // Add the url to the last open tabs list
        // Also save to user defaults
        if let urlString = tabWebView?.url?.absoluteString {
            if !(tabWebView!.url!.isFileURL) {
                lastOpenedTabs.insert(urlString, at: 0)
                
                lastOpenedTabs.removeLast()
                
                UserDefaults.standard.set(lastOpenedTabs, forKey: UserDefaultValues.lastOpenedTabs)
            }
        }
        
        if tabWebView != nil, webView!.isObserving {
            if !(AppConfigurations.isEnergySaverModeOn) {
                // Hide progress indicator
                progressIndicator.isHidden = true
            }
            // Stop it from loading
            tabWebView?.stopLoading()
            // Remove all the observers on the webview
            tabWebView?.removeWebview()
            // Remove from the superview
            tabWebView?.removeFromSuperview()
            // Make it nil
            tabWebView = nil
        }
    }
    
    private func getNewWebViewInstance(config: WKWebViewConfiguration? = nil, url: URL? = nil) -> MAWebView {
        let webConfig = WKWebViewConfiguration()
//        webConfig.processPool = processPool
        let newWebView = MAWebView(frame: .zero, configuration: config ?? webConfig)
        
        newWebView.initializeWebView()
        newWebView.enableConfigurations()
        
        DispatchQueue.global(qos: .background).async {
            newWebView.enableAdblock()
        }
        
        if AppConfigurations.isEnergySaverModeOn {
            newWebView.enableBatterySaver()
        }
        
        if config == nil {
            _ = url != nil ? newWebView.load(.init(url: url!)) : newWebView.loadHTMLString(startPageHTML, baseURL: newtabURL!)
        }
        
        return newWebView
    }
    
    // MARK: - Bookmarks Bar

    func bookmarksBar(_ bookmarksBar: MABookmarksBar, selected item: MABookmarksItem) {
        webView!.load(URLRequest(url: item.url!))
        
        updateWebsiteURL()
    }
    
    func loadBookmarksBar() {
        let dictionary: [String: String]? = defaults.object(forKey: UserDefaultValues.bookmarksBarItem) as? [String: String] ?? nil
        
        if let dictionary = dictionary {
            for dictionary in dictionary {
                bookmarksBar.add(item: MABookmarksItem(title: dictionary.key, url: URL(string: dictionary.value)!))
            }
        } else {
            let dictionary = [String:String]()
            
            defaults.set(dictionary, forKey: UserDefaultValues.bookmarksBarItem)
        }
    }
    
    func addBookmarksItem(title: String, url: URL) {
        var dictionary: [String: String] = defaults.object(forKey: UserDefaultValues.bookmarksBarItem) as! [String: String]
        
        dictionary[title] = url.absoluteString
        
        bookmarksBar.add(item: MABookmarksItem(title: title, url: url))
        
        defaults.set(dictionary, forKey: UserDefaultValues.bookmarksBarItem)
    }
}

// https://stackoverflow.com/questions/68679658/swift-5-4-hex-to-nscolor
extension NSColor {
    convenience init(hex: String) {
        let trimHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let dropHash = String(trimHex.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        let hexString = trimHex.starts(with: "#") ? dropHash : trimHex
        let ui64 = UInt64(hexString, radix: 16)
        let value = ui64 != nil ? Int(ui64!) : 0
        // #RRGGBB
        var components = (
            R: CGFloat((value >> 16) & 0xff) / 255,
            G: CGFloat((value >> 08) & 0xff) / 255,
            B: CGFloat((value >> 00) & 0xff) / 255,
            a: CGFloat(1)
        )
        if String(hexString).count == 8 {
            // #RRGGBBAA
            components = (
                R: CGFloat((value >> 24) & 0xff) / 255,
                G: CGFloat((value >> 16) & 0xff) / 255,
                B: CGFloat((value >> 08) & 0xff) / 255,
                a: CGFloat((value >> 00) & 0xff) / 255
            )
        }
        self.init(red: components.R, green: components.G, blue: components.B, alpha: components.a)
    }
    
    func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if alpha {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

// https://stackoverflow.com/a/63003757
enum ColorBrightness {
    case light
    case dark
}

extension NSColor {
    func mix(type: ColorBrightness) -> Self {
        let ciColor = CIColor(color: self)!
        
        let red = ciColor.red
        let green = ciColor.green
        let blue = ciColor.blue
        
        if type == .dark {
            return Self(
                red: max(red - 0.2, 0.0),
                green: max(green - 0.2, 0.0),
                blue: max(blue - 0.2, 0.0),
                alpha: ciColor.alpha
            )
        } else {
            return Self(
                red: max(red + 0.2, 0.0),
                green: max(green + 0.2, 0.0),
                blue: max(blue + 0.2, 0.0),
                alpha: ciColor.alpha
            )
        }
    }

    func lighter() -> Self { mix(type: .light) }
    func darker() -> Self { mix(type: .dark) }
    
    var isLight: Bool {
        guard let components = cgColor.components, components.count > 2 else { return false }
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        return (brightness > 0.5)
    }
}
