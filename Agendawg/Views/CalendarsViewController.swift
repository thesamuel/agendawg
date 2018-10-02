//
//  CalendarTableViewController.swift
//  Agendawg
//
//  Created by Sam Gehman on 9/1/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit
import EventKit

class CalendarsViewController: UIViewController {

    let eventStore = EKEventStore()
    var calendars: [EKCalendar]?
    var model: Schedule!
    var checkedCalendar: EKCalendar?

    var currentPermissionAlert: UIAlertController?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        doneButton.layer.cornerRadius = 8
        doneButton.clipsToBounds = true

        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        checkCalendarAuthorizationStatus()
    }

    @IBAction func done(_ sender: Any) {
        if let calendar = checkedCalendar {
            if model.saveEvents(toCalendar: calendar, inEventStore: eventStore) {
                print("Events saved successfully.")
                performSegue(withIdentifier: "DoneSegue", sender: self)
            } else {
                print("Error encountered while saving events.")
            }
        }
    }

}

// MARK: - Table view data source

extension CalendarsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return calendars?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarCell", for: indexPath)

        if let calendar = calendars?[indexPath.row] {
            cell.textLabel?.text = calendar.title
            let isChecked = (calendar == checkedCalendar)
            cell.accessoryType = isChecked ? .checkmark : .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let calendar = calendars?[indexPath.row] {
            checkedCalendar = calendar
        }
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

// MARK: - Calendar helper functions

extension CalendarsViewController {

    func checkCalendarAuthorizationStatus() {
        dismissPermissionAlert()
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        switch (status) {
        case EKAuthorizationStatus.notDetermined:
            print("Will request calendar access.")
            requestCalendarAccess()
        case EKAuthorizationStatus.authorized:
            print("Calendar authorized.")
            reloadCalendars()
        case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
            print("Calendar restricted or denied.")
            presentPermissionAlert()
        }
    }

    func requestCalendarAccess() {
        eventStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in
            if accessGranted {
                self.reloadCalendars()
            } else {
                self.presentPermissionAlert()
            }
        })
    }

    func reloadCalendars() {
        DispatchQueue.main.async(execute: {
            self.calendars = self.eventStore.calendars(for: EKEntityType.event)
            self.checkedCalendar = self.calendars?.first
            self.tableView.reloadData()
        })
    }

    func presentPermissionAlert() {
        let permissionAlert = UIAlertController(title: "Calendar access required",
                                                message: "To save the schedule to your calendar, "
                                                    + "please enable Calendars access in Settings.",
                                                preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Go to Settings", style: .default) { (_) in
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
        }
        permissionAlert.addAction(settingsAction)
        currentPermissionAlert = permissionAlert

        DispatchQueue.main.async(execute: {
            self.present(permissionAlert, animated: true, completion: nil)
        })
    }

    func dismissPermissionAlert() {
        if let currentPermissionAlert = currentPermissionAlert {
            currentPermissionAlert.dismiss(animated: false, completion: nil)
        }
        self.currentPermissionAlert = nil
    }

}
