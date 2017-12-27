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

    static let startDate = Date(dateString: "January 3, 2018", format: "MMMM d, yyyy")
    static let endDate = Date(dateString: "March 9, 2018", format: "MMMM d, yyyy")

//    static let startDate = Date(dateString: "September 27, 2017", format: "MMMM d, yyyy")
//    static let endDate = Date(dateString: "December 8, 2017", format: "MMMM d, yyyy")

//    static let registrationURL = URL(string: "https://sdb.admin.uw.edu/students/uwnetid/register.asp")!
    static let registrationURL = URL(string: "http://localhost:8888/Registration.html")!

    static let registrationFormSelector = "form#regform table.sps_table"
    static let lineBreak = "<br>"
    static let cellSelector = "tt"
    static let numberOfHeaderRows = 2
    static let numberOfFooterRows = 2

    enum RegistrationError: Error {
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

}
