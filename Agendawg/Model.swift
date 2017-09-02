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
        case eventError
    }

    private static let registrationTableXpath = "//form/table/tbody/tr/td/tt"

    var courses: [Course]?
    var filteredCourses: [Course]?

    func filterCourses(isIncluded: @escaping (Course) -> Bool) {
        filteredCourses = courses?.filter(isIncluded)
    }

    func saveEvents(toCalendar selectedCalendar: EKCalendar,
                    inEventStore eventStore: EKEventStore) -> Bool {
        guard let calendar = eventStore.calendar(withIdentifier: selectedCalendar.calendarIdentifier) else {
            return false
        }

        guard let events = filteredCourses?.map({ (course) -> EKEvent in
            // Create event
            let event = EKEvent(eventStore: eventStore)
            event.calendar = calendar
            event.title = course.course
            event.location = course.location

            // Set event start/end from course
            event.startDate = course.firstOccurrence.beginning
            event.endDate = course.firstOccurrence.end

            // Add recurrence rules
            let recurrenceRule = Model.weekdayRecurrenceRule(withWeekdays: course.weekdays)
            event.recurrenceRules = [recurrenceRule]

            return event
        }) else {
            return false
        }

        do {
            try events.forEach({ (event) in
                try eventStore.save(event, span: .thisEvent)
            })
        } catch {
            print("Error saving at least one event.")
            return false
        }

        return true
    }

    static func weekdayRecurrenceRule(withWeekdays weekdays: [Course.Weekday]) -> EKRecurrenceRule {
        let recurrenceEnd = EKRecurrenceEnd(end: Constants.endDate)
        let daysOfWeek = weekdays.map({ (weekday) -> EKRecurrenceDayOfWeek in
            guard let eventWeekday = EKWeekday(rawValue: weekday.rawValue) else {
                fatalError()
            }
            return EKRecurrenceDayOfWeek(eventWeekday)
        })

        let recurrenceRule = EKRecurrenceRule(recurrenceWith: .weekly,
                                              interval: 1,
                                              daysOfTheWeek: daysOfWeek,
                                              daysOfTheMonth: nil,
                                              monthsOfTheYear: nil,
                                              weeksOfTheYear: nil,
                                              daysOfTheYear: nil,
                                              setPositions: nil,
                                              end: recurrenceEnd)
        return recurrenceRule
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
