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

    static let registrationFormSelector = "form#regform table.sps_table"
    private static let numberOfHeaderRows = 2
    private static let numberOfFooterRows = 2

    var courses: [Course]?
    var filteredCourses: [Course]?

    func filterCourses(isIncluded: @escaping (Course) -> Bool) {
        filteredCourses = courses?.filter(isIncluded)
    }

    func parseHTML(html: String) -> Bool {
        guard let doc = Kanna.HTML(html: html, encoding: String.Encoding.utf8) else {
            return false
        }

        let registrationTables = doc.css(Model.registrationFormSelector)

        guard registrationTables.count > 0 else {
            return false
        }

        guard let scheduleTableHtml = registrationTables.first?.innerHTML,
            let scheduleTableDoc = Kanna.HTML(html: scheduleTableHtml,
                                              encoding: String.Encoding.utf8) else {
                return false
        }

        let scheduleRows = scheduleTableDoc.css("tr")

        guard let courseRows = Model.courseRows(in: scheduleRows) else {
            return false
        }

        guard let courses = try? courseRows.map(Model.course) else {
            return false
        }

        self.courses = courses
        print("Courses parsed.")
        return true
    }

    static func course(from row: XMLElement) throws -> Course {
        guard let rowHtml = row.innerHTML,
            let rowDoc = Kanna.HTML(html: rowHtml, encoding: String.Encoding.utf8) else {
                throw ModelError.parseError
        }

        let cells = rowDoc.css("tt")
        let trimmedCells = try cells.map({ (cell) throws -> String in
            guard let text = cell.text else {
                throw ModelError.parseError
            }
            return text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        })

        // Create a course from a schedule row
        guard let course = Course(row: trimmedCells) else {
            throw ModelError.parseError
        }

        return course
    }

    // TODO: handle no schedule entry rows
    static func courseRows(in table: XPathObject) -> [XMLElement]? {
        // Ensure that header rows are present, and they contain the correct contents
        guard table.count > numberOfHeaderRows,
            isValidHeaderRow(table[0]),
            isValidHeaderRow(table[1]) else {
            return nil
        }

        let bodyRows = table.dropFirst(numberOfHeaderRows).dropLast(numberOfFooterRows)
        return Array(bodyRows)
    }

    // TODO: add support for different languages
    static func isValidHeaderRow(_ row: XMLElement) -> Bool {
        return true // FIXME
    }

}

// MARK: - Calendar functions

extension Model {

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

            let instructor = "Instructor: " + (course.instructor ?? "unknown")
            let sln = "SLN: " +  String(course.SLN)
            let tag = "Created with Agendawg."

            event.notes = "\(instructor)\n\(sln)\n\n\(tag)"

            // Set event start/end from course
            event.startDate = course.firstOccurrence.beginning!
            event.endDate = course.firstOccurrence.end!

            // Add recurrence rules
            let recurrenceRule = Model.weekdayRecurrenceRule(withWeekdays: course.weekdays,
                                                             recurrenceEndDate: Constants.endDate + 1.days)
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

    static func weekdayRecurrenceRule(withWeekdays weekdays: [EKWeekday],
                                      recurrenceEndDate: Date) -> EKRecurrenceRule {
        let recurrenceEnd = EKRecurrenceEnd(end: recurrenceEndDate)
        let daysOfWeek = weekdays.map({ (weekday) -> EKRecurrenceDayOfWeek in
            return EKRecurrenceDayOfWeek(weekday)
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

}
