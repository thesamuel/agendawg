//
//  ViewController.swift
//  Agendawg
//
//  Created by Sam Gehman on 8/31/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    let registrationURL = URL(string: "https://sdb.admin.uw.edu/students/uwnetid/register.asp")!
    let model = Model()

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.delegate = self
        let request = URLRequest(url: registrationURL)
        webView.loadRequest(request)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? TableViewController else {
            return
        }
        destination.model = model
    }
}

extension ViewController: UIWebViewDelegate {

    func webViewDidFinishLoad(_ webView: UIWebView) {
        guard let html = webView.stringByEvaluatingJavaScript(from: "document.body.innerHTML") else {
            return
        }
        if model.parseHTML(html: html) {
            performSegue(withIdentifier: "SuccessSegue", sender: self)
        }
    }

}
