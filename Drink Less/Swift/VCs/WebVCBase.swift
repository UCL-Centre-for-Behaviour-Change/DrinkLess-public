//
//  WebVCBase.swift
//  drinkless
//
//  Created by Hari Karam Singh on 06/12/2019.
//  Copyright © 2019 Greg Plumbly. All rights reserved.
//

import UIKit

/** Base class replacement for bloated PXWebViewController. We'll encourage subclasses from now on. Can be used standalone too though (remove "Base"?) */
class WebVCBase: PXTrackedViewController, UIWebViewDelegate {

    /** The HTML file name sans extension */
    @IBInspectable public var resource:String?
    @IBInspectable public var bottomMargin:CGFloat = 0
    
    private var webView:UIWebView = UIWebView()

    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////

    override func viewDidLoad() {
        self.view.tag = 440  // horrible tool tip hack
        
        super.viewDidLoad()
        var f = self.view.bounds
        f.size.height -= bottomMargin  // make space if specified
        webView.frame = f
        webView.autoresizingMask = [ .flexibleWidth, .flexibleHeight]
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.delegate = self
        view.addSubview(webView)
        
        // Load HTML in case we need any injections. Root in the bundle base url in case we need to add any images, etc.
        let html = self.loadResourceHTML()
        webView.loadHTMLString(html ?? "", baseURL: Bundle.main.bundleURL)
        
        // For tracking. Title set in IB or by instantiating code
        self.screenName = self.title;

    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Overideable Methods
    //////////////////////////////////////////////////////////

    /** Override if you want to intercept the html */
    public func loadResourceHTML() -> String? {
        let path = Bundle.main.path(forResource: resource, ofType: "html")!
        let html = try? String(contentsOfFile: path)
        return html
    }

    //---------------------------------------------------------------------

    public func handleAppSchemeRequest(_ resourceId:String) {
        
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Protected
    //////////////////////////////////////////////////////////
    
    public func formFieldValue(for formInputId:String) -> String? {
        let jsString = "document.getElementById('consent-form')['\(formInputId)'].value"
        let res = webView.stringByEvaluatingJavaScript(from: jsString )
        return res
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Delegate
    //////////////////////////////////////////////////////////

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        let urlStr = request.url!.absoluteString
        if urlStr[..<urlStr.index(urlStr.startIndex, offsetBy:6)] != "app://" {
            return true
        }
        handleAppSchemeRequest(String(urlStr.dropFirst(6)))
        return false
    }
    
}

