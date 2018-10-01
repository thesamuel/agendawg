//
//  Constants.swift
//  Agendawg
//
//  Created by Sam Gehman on 9/1/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import Foundation
import EventKit

struct Registration {

    static var startDate: Date?
    static var endDate: Date?

    static let registrationURL = URL(string: "https://sdb.admin.uw.edu/students/uwnetid/register.asp")!
//    static let registrationURL = URL(string: "http://localhost:8888/Registration.html")!

    static let registrationFormSelector = "form#regform table.sps_table"
    static let headingSelector = "h1"
    static let lineBreak = "<br>"
    static let cellSelector = "tt"
    static let numberOfHeaderRows = 2
    static let numberOfFooterRows = 2

    enum RegistrationError: Error {
        case invalidQuarter
        case invalidTimeFormat(String)
        case invalidHoursFormat(String)
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

    enum CourseType: String {
        case lecture = "LC"
        case quiz = "QZ"
        case seminar = "SM"
    }

    struct AcademicCalendar: Codable {
        let dates: [String: QuarterDates]
    }

    struct QuarterDates: Codable {
        let start: String
        let end: String

        var startDate: Date {
            return Date(dateString: start, format: "MMMM d, yyyy")
        }

        var endDate: Date {
            return Date(dateString: end, format: "MMMM d, yyyy")
        }
    }

    static func setHeading(heading: String) throws {
        guard let quarter = heading.components(separatedBy: "Registration - ").first else {
            throw RegistrationError.invalidQuarter
        }
        let dates = try! quarterDates(for: quarter)
        startDate = dates.startDate
        endDate = dates.endDate
    }

    static func quarterDates(for quarterString: String) throws -> QuarterDates {
        // File should always be in bundle
        let datesURL = Bundle.main.url(forResource: "dates", withExtension: "json")!
        let datesData = try! Data(contentsOf: datesURL)

        let decoder = JSONDecoder()
        let academicCalendar = try! decoder.decode(AcademicCalendar.self, from: datesData)

        guard let dates = academicCalendar.dates[quarterString.lowercased()] else {
            throw RegistrationError.invalidQuarter
        }
        return dates
    }

    static func emoji(for course: String) -> Course.Major {
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

        return Course.Major.unknown
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
                throw RegistrationError.invalidHoursFormat(String(hour))
            }
            return trimmed + (hourInt >= 7 && hourInt < 12 ? " AM" : " PM")
        }

        guard formattedTimes.count == 2 else {
            throw RegistrationError.invalidTimeFormat(timeString)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hhmm a"
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        return try formattedTimes.map { (time) throws -> Date in
            guard let date = dateFormatter.date(from: time) else {
                throw RegistrationError.invalidTimeFormat(timeString)
            }
            return date
        }
    }

    static func weekdays(for daysString: String) -> [EKWeekday] {
        var weekdays = [EKWeekday]()

        if daysString.contains("M") {
            weekdays.append(EKWeekday.monday)
        }
        if daysString.range(of: "T(?!h)", options: .regularExpression) != nil {
            weekdays.append(EKWeekday.tuesday)
        }
        if daysString.contains("W") {
            weekdays.append(EKWeekday.wednesday)
        }
        if daysString.contains("Th") {
            weekdays.append(EKWeekday.thursday)
        }
        if daysString.contains("F") {
            weekdays.append(EKWeekday.friday)
        }

        return weekdays
    }

    static func firstWeekdayDate(for weekday: EKWeekday) -> Date {
        var date = startDate!

        while date.weekday != weekday.rawValue {
            date = date.add(1.days)
        }

        return date
    }
}
