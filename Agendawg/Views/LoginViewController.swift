//
//  ViewController.swift
//  Agendawg
//
//  Created by Sam Gehman on 8/31/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    let registrationURL = URL(string: "https://sdb.admin.uw.edu/students/uwnetid/register.asp")!
    var parseHTML: ((String) -> Void)!
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.delegate = self
        let request = URLRequest(url: registrationURL)
        webView.loadRequest(request)

        let activityBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        navigationItem.rightBarButtonItem = activityBarButtonItem
    }

}

// MARK: - UIWebViewDelegate

extension LoginViewController: UIWebViewDelegate {

    func webViewDidStartLoad(_ webView: UIWebView) {
        activityIndicator.startAnimating()
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        activityIndicator.stopAnimating()
        if let html = webView.stringByEvaluatingJavaScript(from: "document.body.innerHTML") {
            parseHTML(html)
        }
    }

}
