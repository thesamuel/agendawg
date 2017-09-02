//
//  Course.swift
//  Agendawg
//
//  Created by Sam Gehman on 8/31/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import Foundation
import DateToolsSwift
import EventKit

struct Course {

    enum CourseType: String {
        case lecture = "LC"
        case quiz = "QZ"
    }

    enum Emoji: String {
        case anthropology = "👴🏻"
        case bioengineering = "🔬"
        case biology = "🐒"
        case business = "💰"
        case cse = "💻"
        case informatics = "📈"
        case math = "🆘"
        case mechanical = "⚙️"
        case nursing = "🏥"
        case psychology = "🤔"
        case unknown = "🎓"
    }

    enum Index: Int {
        case SLN = 0    // 0. "10290"
        case course     // 1. "ANTH 101 A"
        case type       // 2. "LC"
        case credits    // 3. "5.0"
        case grading    // 4. "standard\nS/NS\n" (ignore)
        case title      // 5. "EXPLORING SOC ANTHR"
        case days       // 6. "MW"
        case time       // 7. "130- 320" or "1030-1120"
        case location   // 8. "JHN 102"
        case instructor // 9. "Perez,Michael Vincente"
    }

    enum CourseError: Error {
        case invalidTimeFormat(String)
        case invalidNumberOfDays(Int)
        case noDateOfFirstOccurrence
        case invalidHoursFormat(String)
    }

    let SLN: Int
    let course: String
    let title: String
    let type: CourseType
    let firstOccurrence: TimePeriod
    let weekdays: [EKWeekday]

    let credits: Double?
    let location: String?
    let instructor: String?
    let emoji: Emoji?

    init?(row: [String]) {
        guard row.count == 10 else {
            print("Course row did not contain 10 elements.")
            return nil
        }

        guard let SLN = Int(row[Index.SLN.rawValue]),
            let type = CourseType(rawValue: row[Index.type.rawValue]) else {
                print("Course row contained invalid SLN or course type.")
                return nil
        }

        // Required properties
        self.SLN = SLN
        self.type = type
        course = row[Index.course.rawValue]
        title = row[Index.title.rawValue]

        // Create TimePeriods from days and time
        let time = row[Index.time.rawValue]
        let days = row[Index.days.rawValue]
        weekdays = Course.weekdays(for: days)
        guard let firstOccurrence = try? Course.firstOccurrence(withTime: time, weekdays: weekdays) else {
            return nil
        }
        self.firstOccurrence = firstOccurrence

        // Save Optional properties
        credits = Double(row[Index.credits.rawValue])
        emoji = Course.emoji(for: course)

        let location = row[Index.location.rawValue]
        self.location = !location.isEmpty ? location : nil

        let instructor = row[Index.instructor.rawValue]
        self.instructor = !instructor.isEmpty ? instructor : nil
    }

    static func emoji(for course: String) -> Emoji? {
        let components = course.components(separatedBy: " ")
        guard let department = components.first?.lowercased() else {
            return nil
        }
        switch department {
        case "anth", "archy", "bio a":
            return .anthropology
        case "bioen", "marbio", "medeng", "pharbe":
            return .bioengineering
        case "biol":
            return .biology
        case "acctg", "admin", "b a", "ba rm",
             "b cmu", "b econ", "b pol", "ebiz",
             "entre", "fin", "hrmob", "i s",
             "msis", "i bus", "mgmt", "mktg",
             "opmgt", "o e", "qmeth", "st mgt",
             "scm":
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
        return Emoji.unknown
    }

}

extension Course: Hashable {

    var hashValue: Int {
        return SLN.hashValue
    }

    static func == (lhs: Course, rhs: Course) -> Bool {
        return lhs.SLN == rhs.SLN
    }
    
}

// MARK: Date functions

extension Course {

    static let dayChunk = TimeChunk(seconds: 0, minutes: 0, hours: 0, days: 1,
                                    weeks: 0, months: 0, years: 0)

    static func firstOccurrence(withTime timeString: String, weekdays: [EKWeekday]) throws -> TimePeriod {
        guard weekdays.count > 0, weekdays.count <= 5 else {
            throw CourseError.invalidNumberOfDays(weekdays.count)
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
                throw CourseError.noDateOfFirstOccurrence
        }

        let timesOfFirstOccurrence = try times(for: timeString)

        let adjustedDates = timesOfFirstOccurrence.map({ (date) -> Date in
            var date = date
            date.day(dateOfFirstOccurrence.day)
            date.month(dateOfFirstOccurrence.month)
            date.year(dateOfFirstOccurrence.year)
            return date
        })
        return TimePeriod(beginning: adjustedDates[0], end: adjustedDates[1])
    }

    static func weekdays(for daysString: String) -> [EKWeekday] {
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

    static func firstWeekdayDate(for weekday: EKWeekday, startDate: Date) -> Date {
        var date = startDate
        while(date.weekday != weekday.rawValue) {
            date = date.add(dayChunk)
        }
        return date
    }

    static func times(for timeString: String) throws -> [Date] {
        let timeComponents = timeString.components(separatedBy: "-")

        let formattedTimes = try timeComponents.map { (time) throws -> String in
            var trimmed = time.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if trimmed.count == 3 {
                trimmed = "0" + trimmed
            }

            let hourIndex = trimmed.index(trimmed.startIndex, offsetBy: 2)
            let hour = trimmed[..<hourIndex]
            guard let hourInt = Int(hour) else {
                throw CourseError.invalidHoursFormat(String(hour))
            }
            return trimmed + (hourInt >= 7 && hourInt < 12 ? " AM" : " PM")
        }

        guard formattedTimes.count == 2 else {
            throw CourseError.invalidTimeFormat(timeString)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hhmm a"
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        return formattedTimes.map { (time) -> Date in
            guard let date = dateFormatter.date(from: time) else {
                fatalError()
            }
            return date
        }
    }

}
