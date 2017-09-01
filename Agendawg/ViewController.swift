//
//  ViewController.swift
//  Agendawg
//
//  Created by Sam Gehman on 8/31/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var parseBarButton: UIBarButtonItem!
    @IBOutlet weak var webView: UIWebView!
    let registrationURL = URL(string: "https://sdb.admin.uw.edu/students/uwnetid/register.asp")!
    let model = Model()

    override func viewDidLoad() {
        super.viewDidLoad()

        let times = Course.dates(forTime: "130- 320", days: "TTh")

        webView.delegate = self
        let request = URLRequest(url: registrationURL)
        webView.loadRequest(request)
    }
}

extension ViewController: UIWebViewDelegate {

    func webViewDidFinishLoad(_ webView: UIWebView) {
        if let html = webView.stringByEvaluatingJavaScript(from: "document.body.innerHTML") {
            model.parseHTML(html: html)
        }
    }

}
