//
//  WelcomeViewController.swift
//  Agendawg
//
//  Created by Sam Gehman on 9/1/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {

    @IBOutlet weak var continueButton: UIButton!
    let model = Model()
    var loginViewController: LoginViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func parseHTML(_ html: String) {
        if model.parseHTML(html: html) {
            self.performSegue(withIdentifier: "SuccessSegue", sender: self)
            loginViewController?.dismiss(animated: true, completion: nil)
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationViewController = segue.destination as? UINavigationController {
            if let loginViewController = navigationViewController.viewControllers[0] as? LoginViewController {
                loginViewController.parseHTML = parseHTML
                self.loginViewController = loginViewController
            }
        } else if let tableViewController = segue.destination as? TableViewController {
            tableViewController.model = model
        }
    }

}
