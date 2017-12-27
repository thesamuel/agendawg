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
    let credits: Double
    let emoji: Major

    // MARK: Comparison
    var hashValue: Int {
        return SLN.hashValue
    }

    static func == (lhs: Course, rhs: Course) -> Bool {
        return lhs.SLN == rhs.SLN
    }

}
