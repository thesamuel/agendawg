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

        continueButton.layer.cornerRadius = 8
        continueButton.clipsToBounds = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    func parseHTML(_ html: String) {
        if model.parseHTML(html: html) {
            self.performSegue(withIdentifier: "CoursesSegue", sender: self)
            loginViewController?.dismiss(animated: true, completion: nil)
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationViewController = segue.destination as? UINavigationController {
            if let loginViewController = navigationViewController.viewControllers.first as? LoginViewController {
                loginViewController.parseHTML = parseHTML
                self.loginViewController = loginViewController
            }
        } else if let coursesViewController = segue.destination as? CoursesViewController {
            coursesViewController.model = model
        }
    }

}
