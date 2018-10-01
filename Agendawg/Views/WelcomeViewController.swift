//
//  WelcomeViewController.swift
//  Agendawg
//
//  Created by Sam Gehman on 9/1/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController, LoginViewControllerDelegate {

    @IBOutlet weak var continueButton: UIButton!
    let model = Schedule()
    var loginViewController: LoginViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        continueButton.layer.cornerRadius = 8
        continueButton.clipsToBounds = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        #if DEBUG
        // Skip the welcome screen if we're debugging
        self.performSegue(withIdentifier: "LoginSegue", sender: self)
        #endif

        // Hide the navigation bar
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationViewController = segue.destination as? UINavigationController {
            if let loginViewController = navigationViewController.viewControllers.first as? LoginViewController {
                loginViewController.delegate = self
            }
        } else if let coursesViewController = segue.destination as? CoursesViewController {
            coursesViewController.model = model
        }
    }

    // MARK: - LoginViewControllerDelegate functions

    func parseHTML(_ loginViewController: LoginViewController, _ html: String) {
        if model.parseHTML(html: html) {
            self.performSegue(withIdentifier: "CoursesSegue", sender: self)
            loginViewController.dismiss(animated: true, completion: nil)
        }
    }

}

// MARK: - LoginViewControllerDelegate

protocol LoginViewControllerDelegate: class {

    func parseHTML(_ loginViewController: LoginViewController, _ html: String)

}
