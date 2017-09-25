//
//  ViewController.swift
//  Agendawg
//
//  Created by Sam Gehman on 8/31/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    weak var delegate: LoginViewControllerDelegate!
    @IBOutlet weak var webView: UIWebView!
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.delegate = self
        load()

        let activityBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        navigationItem.rightBarButtonItem = activityBarButtonItem
    }

    func load() {
        let request = URLRequest(url: Constants.registrationURL)
        webView.loadRequest(request)
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
            delegate.parseHTML(self, html)
        }
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        let alert = UIAlertController(title: "Failed to load MyUW",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)

        let closeAction = UIAlertAction(title: "Close", style: .cancel) { _ in
            self.dismiss(animated: true, completion: nil)
        }

        let retryAction = UIAlertAction(title: "Retry", style: .default) { _ in
            self.load()
        }

        alert.addAction(closeAction)
        alert.addAction(retryAction)

        self.present(alert, animated: true, completion: nil)
    }

}
