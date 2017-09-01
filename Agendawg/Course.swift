//
//  Course.swift
//  Agendawg
//
//  Created by Sam Gehman on 8/31/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import Foundation
import DateToolsSwift

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
        case InvalidTimeFormat(String)
    }

    let SLN: Int
    let course: String
    let title: String
    let type: CourseType
    let dates: [TimePeriod]

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
        dates = Course.dates(forTime: time, days: days)

        // Optional properties
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

// MARK: dates functions

extension Course {

    static let startDate = Date(dateString: "September 27, 2017", format: "MMMM d, yyyy")
    static let endDate = Date(dateString: "December 8, 2017", format: "MMMM d, yyyy")
    static let dayChunk = TimeChunk(seconds: 0, minutes: 0, hours: 0, days: 1,
                                    weeks: 0, months: 0, years: 0)

    enum Weekday: Int {
        case monday = 2
        case tuesday
        case wednesday
        case thursday
        case friday
    }

    static func dates(forTime time: String, days: String) -> [TimePeriod] {
        let formattedTime = formatTime(time: time)
        guard formattedTime.count == 2 else {
            fatalError()
        }

        let formattedWeekdays = weekdays(for: days)
        guard formattedWeekdays.count > 0 else {
            fatalError()
        }

        return formattedWeekdays.map { (weekday) -> TimePeriod in
            let adjustedDates = formattedTime.map({ (date) -> Date in
                let adjustmentDate = firstWeekday(weekday: weekday, date: startDate)
                var date = date
                date.day(adjustmentDate.day)
                date.month(adjustmentDate.month)
                date.year(adjustmentDate.year)
                return date
            })
            return TimePeriod(beginning: adjustedDates[0],
                              end: adjustedDates[1])
        }
    }

    static func weekdays(for days: String) -> [Weekday] {
        var formattedWeekdays = [Weekday]()
        var foundT = false
        days.forEach { (character) in
            if foundT {
                let additionalWeekday = character == "h" ? Weekday.thursday : Weekday.tuesday
                formattedWeekdays.append(additionalWeekday)
                foundT = false
            }
            if character == "T" {
                foundT = true
            }
        }
        if foundT == true {
            formattedWeekdays.append(Weekday.tuesday)
        }

        if days.contains("M") {
            formattedWeekdays.append(Weekday.monday)
        }
        if days.contains("W") {
            formattedWeekdays.append(Weekday.wednesday)
        }
        if days.contains("F") {
            formattedWeekdays.append(Weekday.friday)
        }

        return formattedWeekdays
    }

    static func firstWeekday(weekday: Weekday, date: Date) -> Date {
        var date = date
        while(date.weekday != weekday.rawValue) {
            date = date.add(dayChunk)
        }
        return date
    }

    static func formatTime(time: String) -> [Date] {
        let timeComponents = time.components(separatedBy: "-")
        let formattedTime = timeComponents.map { (time) -> String in
            var trimmed = time.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if trimmed.count == 3 {
                trimmed = "0" + trimmed
            }

            let hourIndex = trimmed.index(trimmed.startIndex, offsetBy: 2)
            let hour = trimmed.substring(to: hourIndex)
            guard let hourInt = Int(hour) else {
                fatalError()
            }
            return trimmed + (hourInt >= 7 && hourInt < 12 ? " AM" : " PM")
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hhmm a"
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        return formattedTime.map { (time) -> Date in
            guard let date = dateFormatter.date(from: time) else {
                fatalError()
            }
            return date
        }
    }

}
