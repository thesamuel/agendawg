//
//  DoneViewController.swift
//  Agendawg
//
//  Created by Sam Gehman on 9/2/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit

class DoneViewController: UIViewController {

    static let personalWebsiteURL = URL(string:"http://www.samgehman.com/")!
    static let icons8URL = URL(string:"https://icons8.com/icon/41662/News")!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func openPersonalWebsite(_ sender: Any) {
        UIApplication.shared.open(DoneViewController.personalWebsiteURL,
                                  options: [:],
                                  completionHandler: nil)
    }

    @IBAction func openIcons8Website(_ sender: Any) {
        UIApplication.shared.open(DoneViewController.icons8URL,
                                  options: [:],
                                  completionHandler: nil)
    }

}
