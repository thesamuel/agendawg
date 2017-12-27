//
//  CourseBuilder.swift
//  Agendawg
//
//  Created by Sam Gehman on 12/26/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit
import DateToolsSwift
import EventKit

class CourseBuilder: NSObject {

    enum CourseBuilderError: Error {
        case generalParseError
        case parseError(String)
        case invalidNumberOfDays(Int)
        case noDateOfFirstOccurrence
    }

    var SLN: String?
    var course: String?
    var title: String?
    var daysList: [String]?
    var timesList: [String]?
    var type: Registration.CourseType?
    var credits: String?
    var locations: [String]?
    var instructors: [String]?

    func build() throws -> Course {
        // Ensure that all needed fields are non-nil
        guard
            let rawSLN = SLN,
            let course = course,
            let title = title,
            let daysList = daysList,
            let timesList = timesList,
            let rawCredits = credits,
            let locations = locations,
            let instructors = instructors
            else {
                throw CourseBuilderError.generalParseError
        }

        // Parse SLN and credits from Strings
        guard
            let SLN = CourseBuilder.trimmedSLN(rawSLN),
            let credits = rawCredits.isEmpty ? 0 : Double(rawCredits)
            else {
                throw CourseBuilderError.generalParseError
        }

        // Ensure that number of days, times, instructors, and locations are equivalent
        guard
            daysList.count == timesList.count,
            daysList.count == instructors.count,
            daysList.count == locations.count
            else {
                throw CourseBuilderError.generalParseError
        }

        // Create meetings for each (day, time, instructor, location) tuple
        var meetings = [Course.Meeting]()
        for (index, days) in daysList.enumerated() {
            let location = locations[index]
            let instructor = instructors[index]

            let weekdays = Registration.weekdays(for: days)
            let time = timesList[index]
            let firstOccurrence = try CourseBuilder.firstOccurrence(withTime: time,
                                                                    weekdays: weekdays)

            let meeting = Course.Meeting(firstOccurrence: firstOccurrence,
                                         weekdays: weekdays,
                                         location: location,
                                         instructor: instructor)

            meetings.append(meeting)
        }

        let emoji = Registration.emoji(for: course)

        return Course(SLN: SLN, course: course, title: title, meetings: meetings, type: type,
                      credits: credits, emoji: emoji)
    }

    static func trimmedSLN(_ rawSLN: String) -> Int? {
        let trimmedSLN = String(rawSLN.prefix(5))
        guard trimmedSLN.count == 5 else {
            return nil
        }
        return Int(trimmedSLN)
    }

    private static func firstOccurrence(withTime timeString: String,
                                        weekdays: [EKWeekday]) throws -> TimePeriod {
        guard weekdays.count > 0, weekdays.count <= 5 else {
            throw CourseBuilderError.invalidNumberOfDays(weekdays.count)
        }

        guard let dateOfFirstOccurrence =
            weekdays.map({ (weekday) -> Date in
                return firstWeekdayDate(for: weekday, startDate: Registration.startDate)
            }).reduce(nil, { (result, date) -> Date in
                guard let previousDate = result else {
                    return date
                }
                return previousDate.isLater(than: date) ? date : previousDate
            })
            else {
                throw CourseBuilderError.noDateOfFirstOccurrence
        }

        let timesOfFirstOccurrence = try Registration.times(for: timeString)

        let adjustedDates = timesOfFirstOccurrence.map({ (date) -> Date in
            var dateCopy = date
            dateCopy.day(dateOfFirstOccurrence.day)
            dateCopy.month(dateOfFirstOccurrence.month)
            dateCopy.year(dateOfFirstOccurrence.year)
            return dateCopy
        })
        return TimePeriod(beginning: adjustedDates[0], end: adjustedDates[1])
    }

    private static func firstWeekdayDate(for weekday: EKWeekday, startDate: Date) -> Date {
        var date = startDate
        while(date.weekday != weekday.rawValue) {
            date = date.add(1.days)
        }
        return date
    }
}
