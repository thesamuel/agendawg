//
//  Model.swift
//  Agendawg
//
//  Created by Sam Gehman on 8/31/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit
import Kanna
import EventKit

class Model: NSObject {

    enum ModelError: Error {
        case parseError
    }

    static let registrationTableXpath = "//form/table/tbody/tr/td/tt"
    var courses: [Course]?

//    func event(forCourse: Course) -> EKEvent {
//
//    }

    func parseHTML(html: String) -> Bool {
        guard let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) else {
            return false
        }

        let registrationTableElements = doc.xpath(Model.registrationTableXpath)
        guard registrationTableElements.count > 0 else {
            return false
        }

        var rows = [[String]]()
        var currentRow = [String]()
        for element in registrationTableElements {
            if currentRow.count >= 10 {
                rows.append(currentRow)
                currentRow = [String]()
            }

            guard let text = element.text else {
                print("Error parsing HTML.")
                return false
            }

            let trimmed = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            currentRow.append(trimmed)
        }

        guard let courses = try? rows.map { (row) -> Course in
            guard let course = Course(row: row) else {
                throw ModelError.parseError
            }
            return course
            }, courses.count > 0 else {
                return false
        }

        self.courses = courses
        print("Courses parsed.")
        return true
    }

}
