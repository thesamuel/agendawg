//
//  TableViewController.swift
//  Agendawg
//
//  Created by Sam Gehman on 9/1/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit
import EventKit

class CoursesViewController: UIViewController {

    var checked = [Course: Bool]()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nextButton: UIButton!

    var model: Schedule! {
        didSet {
            checked.removeAll()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.layer.cornerRadius = 8
        nextButton.clipsToBounds = true

        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? CalendarsViewController {
            filterCourses()
            destination.model = model
        }
    }

    func filterCourses() {
        model.filterCourses(isIncluded: { (course) -> Bool in
            guard let shouldInclude = self.checked[course] else {
                print("Course \(course.title) not found in list of checked courses. Including it.")
                return true
            }
            return shouldInclude
        })
    }

}

// MARK: - Table view data source

extension CoursesViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.courses?.count ?? 0
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CourseCell",
                                                 for: indexPath)

        guard let courseCell = cell as? CourseTableViewCell else {
            print("Cell was not of type CourseCell.")
            return cell
        }

        guard let course = model.courses?[indexPath.row] else {
            print("Course for TableView row \(indexPath.row) not found in model.")
            return courseCell
        }
        courseCell.title = course.title.capitalized
        courseCell.detail = course.course
        courseCell.emoji = course.emoji
        if let isCourseChecked = checked[course] {
            courseCell.accessoryType = isCourseChecked ? .checkmark : .none
        } else { // all courses have checkmarks by default
            checked[course] = true
            courseCell.accessoryType = .checkmark
        }

        return courseCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath), let course = model.courses?[indexPath.row],
            let isCourseChecked = checked[course] {
            let newValue = !isCourseChecked
            checked[course] = newValue
            cell.accessoryType = newValue ? .checkmark : .none
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
