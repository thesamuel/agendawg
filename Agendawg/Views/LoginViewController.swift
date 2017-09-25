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
    var parseHTML: ((String) -> Void)!
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.delegate = self
        let request = URLRequest(url: Constants.registrationURL)
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

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        let alert = UIAlertController(title: "Failed to load MyUW",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)

        let closeAction = UIAlertAction(title: "Close", style: .cancel) { _ in
            // TODO: dismiss this controller
        }

        let retryAction = UIAlertAction(title: "Retry", style: .default) { _ in
            // TODO: reload the page
        }

        alert.addAction(closeAction)
        alert.addAction(retryAction)

        self.present(alert, animated: true, completion: nil)
    }

}
