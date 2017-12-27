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

class Schedule: NSObject {

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

    /// Builds a model from given HTML
    ///
    /// - Parameter html: HTML to create model from
    /// - Returns: true if successful, false if not the correct page
    /// - Throws: exception if invalid
    func parseHTML(html: String) -> Bool {
        guard let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) else {
            return false // not valid HTML
        }

        let registrationTables = doc.css(Schedule.registrationFormSelector)

        guard registrationTables.count > 0 else {
            return false // not the registration page
        }

        guard
            let scheduleTableHtml = registrationTables.first?.innerHTML,
            let scheduleTableDoc = try? Kanna.HTML(html: scheduleTableHtml,
                                                   encoding: String.Encoding.utf8)
            else {
                return false // TODO: should throw an error
        }

        let scheduleRows = scheduleTableDoc.css("tr")

        guard let courseRows = Schedule.courseRows(in: scheduleRows) else {
            return false
        }

        guard let courses = try? courseRows.map(CourseFactory.makeCourse) else {
            return false // TODO: this should throw an error
        }

        self.courses = courses // TODO: this should be a builder
        print("Courses parsed.")
        return true
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

extension Schedule {

    func saveEvents(toCalendar selectedCalendar: EKCalendar,
                    inEventStore eventStore: EKEventStore) -> Bool {
        guard
            let calendar = eventStore.calendar(withIdentifier: selectedCalendar.calendarIdentifier)
            else { return false }

        guard let events = filteredCourses?.flatMap({ course in
            course.meetings.map({ (meeting) -> EKEvent in
                // Create event
                let event = EKEvent(eventStore: eventStore)
                event.calendar = calendar
                event.title = course.course
                event.location = meeting.location

                let instructor = "Instructor: " + (meeting.instructor)
                let SLN = "SLN: " + String(course.SLN)
                let tag = "Created with Agendawg."
                event.notes = "\(instructor)\n\(SLN)\n\n\(tag)"

                // Set event start/end from course
                event.startDate = meeting.firstOccurrence.beginning!
                event.endDate = meeting.firstOccurrence.end!

                // Add recurrence rules
                let recurrenceRule = Schedule.weekdayRecurrenceRule(withWeekdays: meeting.weekdays,
                                                                 recurrenceEndDate: Constants.endDate
                                                                    + 1.days)
                event.recurrenceRules = [recurrenceRule]

                return event
            })
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
