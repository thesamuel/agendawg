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

struct Course: Hashable {

    enum Major: String {
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

    struct Meeting {
        let firstOccurrence: TimePeriod
        let weekdays: [EKWeekday]
        let location: String
        let instructor: String
    }

    // MARK: Properties
    let SLN: Int
    let course: String
    let title: String
    let meetings: [Meeting]
    let type: Registration.CourseType?
    let credits: Double?
    let emoji: Major

    static func emoji(for course: String) -> Major {
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

        return Major.unknown
    }

    // MARK: Comparison
    var hashValue: Int {
        return SLN.hashValue
    }

    static func == (lhs: Course, rhs: Course) -> Bool {
        return lhs.SLN == rhs.SLN
    }

}
