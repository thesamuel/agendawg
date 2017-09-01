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
import DateToolsSwift

class Model: NSObject {

    enum ModelError: Error {
        case parseError
    }

    var courses: [Course]?
    private static let registrationTableXpath = "//form/table/tbody/tr/td/tt"
    private var filteredCourses: [Course]?

    func filterCourses(isIncluded: @escaping (Course) -> Bool) {
        filteredCourses = courses?.filter(isIncluded)
    }

    func saveEvents(toCalendar selectedCalendar: EKCalendar,
                    inEventStore eventStore: EKEventStore) -> Bool {
        guard let calendar = eventStore.calendar(withIdentifier: selectedCalendar.calendarIdentifier) else {
            return false
        }

        print("Testing: will only save first course.")
        guard let course = courses?.first else {
            return false
        }

        // Create event
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = course.title

        // Set event start/end from course
        guard let timePeriod = course.dates.first else {
            return false
        }
        event.startDate = timePeriod.beginning
        event.endDate = timePeriod.end

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            return false
        }

        return true
    }

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
