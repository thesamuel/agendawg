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
        case invalidTimeFormat(String)
        case invalidNumberOfDays(Int)
        case noDateOfFirstOccurrence
        case invalidHoursFormat(String)
    }

    var SLN: String?
    var course: String?
    var title: String?
    var daysList: [String]?
    var timesList: [String]?
    var type: Course.CourseType?
    var credits: String?
    var locations = [String]()
    var instructors = [String]()

    override init() {
        super.init()
    }

    func build() throws -> Course {
        // Ensure that all needed fields are non-nil
        guard
            let rawSLN = SLN,
            let course = course,
            let title = title,
            let daysList = daysList,
            let timesList = timesList,
            let rawCredits = credits
            else {
                throw CourseBuilderError.generalParseError
        }

        // Parse SLN and credits from Strings
        guard
            let SLN = CourseBuilder.parseSLN(rawSLN),
            let credits = Double(rawCredits)
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

            let weekdays = CourseBuilder.weekdays(for: days)
            let time = timesList[index]
            let firstOccurrence = try CourseBuilder.firstOccurrence(withTime: time,
                                                                    weekdays: weekdays)

            let meeting = Course.Meeting(firstOccurrence: firstOccurrence,
                                         weekdays: weekdays,
                                         location: location,
                                         instructor: instructor)

            meetings.append(meeting)
        }

        let emoji = CourseBuilder.emoji(for: course)

        return Course(SLN: SLN, course: course, title: title, meetings: meetings, type: type,
                      credits: credits, emoji: emoji)
    }

    static func parseSLN(_ rawSLN: String) -> Int? {
        let trimmedSLN = String(rawSLN.prefix(5))
        guard trimmedSLN.count == 5 else {
            return nil
        }
        return Int(trimmedSLN)
    }

    private static func emoji(for course: String) -> Course.Emoji {
        let components = course.components(separatedBy: " ")
        if let department = components.first?.lowercased() {
            switch department {
            case "anth", "archy", "bio a":
                return .anthropology
            case "bioen", "marbio", "medeng", "pharbe":
                return .bioengineering
            case "biol":
                return .biology
            case "acctg", "admin", "b a", "ba rm", "b cmu", "b econ", "b pol", "ebiz", "entre",
                 "fin", "hrmob", "i s", "msis", "i bus", "mgmt", "mktg", "opmgt", "o e", "qmeth",
                 "st mgt", "scm":
                return .business
            case "cse":
                return .cse
            case "info", "infx", "insc", "imt", "lis":
                return .informatics
            case "math", "amath", "cfrm":
                return .math
            case "m e", "meie":
                return .mechanical
            case "nsg", "nurs", "nclin", "nmeth":
                return .nursing
            case "psych":
                return .psychology
            default:
                break
            }
        }

        return Course.Emoji.unknown
    }

    private static func firstOccurrence(withTime timeString: String,
                                weekdays: [EKWeekday]) throws -> TimePeriod {
        guard weekdays.count > 0, weekdays.count <= 5 else {
            throw CourseBuilderError.invalidNumberOfDays(weekdays.count)
        }

        guard let dateOfFirstOccurrence =
            weekdays.map({ (weekday) -> Date in
                return firstWeekdayDate(for: weekday, startDate: Constants.startDate)
            }).reduce(nil, { (result, date) -> Date in
                guard let previousDate = result else {
                    return date
                }
                return previousDate.isLater(than: date) ? date : previousDate
            }) else {
                throw CourseBuilderError.noDateOfFirstOccurrence
        }

        let timesOfFirstOccurrence = try times(for: timeString)

        let adjustedDates = timesOfFirstOccurrence.map({ (date) -> Date in
            var dateCopy = date
            dateCopy.day(dateOfFirstOccurrence.day)
            dateCopy.month(dateOfFirstOccurrence.month)
            dateCopy.year(dateOfFirstOccurrence.year)
            return dateCopy
        })
        return TimePeriod(beginning: adjustedDates[0], end: adjustedDates[1])
    }

    private static func times(for timeString: String) throws -> [Date] {
        let timeComponents = timeString.components(separatedBy: "-")

        let formattedTimes = try timeComponents.map { (time) throws -> String in
            var trimmed = time.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if trimmed.count == 3 {
                trimmed = "0" + trimmed
            }

            let hourIndex = trimmed.index(trimmed.startIndex, offsetBy: 2)
            let hour = trimmed[..<hourIndex]
            guard let hourInt = Int(hour) else {
                throw CourseBuilderError.invalidHoursFormat(String(hour))
            }
            return trimmed + (hourInt >= 7 && hourInt < 12 ? " AM" : " PM")
        }

        guard formattedTimes.count == 2 else {
            throw CourseBuilderError.invalidTimeFormat(timeString)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hhmm a"
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        return try formattedTimes.map { (time) throws -> Date in
            guard let date = dateFormatter.date(from: time) else {
                throw CourseBuilderError.invalidTimeFormat(timeString)
            }
            return date
        }
    }

    private static func weekdays(for daysString: String) -> [EKWeekday] {
        var formattedWeekdays = [EKWeekday]()
        var foundLetterT = false
        daysString.forEach { (character) in
            if foundLetterT {
                let additionalWeekday = character == "h" ? EKWeekday.thursday : EKWeekday.tuesday
                formattedWeekdays.append(additionalWeekday)
                foundLetterT = false
            }
            if character == "T" {
                foundLetterT = true
            }
        }

        if foundLetterT == true {
            formattedWeekdays.append(EKWeekday.tuesday)
        }
        if daysString.contains("M") {
            formattedWeekdays.append(EKWeekday.monday)
        }
        if daysString.contains("W") {
            formattedWeekdays.append(EKWeekday.wednesday)
        }
        if daysString.contains("F") {
            formattedWeekdays.append(EKWeekday.friday)
        }

        return formattedWeekdays
    }

    private static func firstWeekdayDate(for weekday: EKWeekday, startDate: Date) -> Date {
        var date = startDate
        while(date.weekday != weekday.rawValue) {
            date = date.add(1.days)
        }
        return date
    }

}
