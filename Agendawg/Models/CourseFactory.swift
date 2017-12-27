//
//  CourseFactory.swift
//  Agendawg
//
//  Created by Sam Gehman on 12/26/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit
import Kanna
import EventKit
import DateToolsSwift

class CourseFactory: NSObject {

    enum CourseFactoryError: Error {
        case generalParseError
        case parseError(String)
        case invalidTimeFormat(String)
        case invalidNumberOfDays(Int)
        case noDateOfFirstOccurrence
        case invalidHoursFormat(String)
    }

    enum CourseType: String {
        case lecture = "LC"
        case quiz = "QZ"
        case seminar = "SM"
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

    static func makeCourse(from row: XMLElement) throws -> Course {
        guard
            let rowHtml = row.innerHTML,
            let rowDoc = try? Kanna.HTML(html: rowHtml, encoding: String.Encoding.utf8)
            else {
                throw CourseFactoryError.generalParseError
        }

        let builder = CourseBuilder()
        let cells = rowDoc.css("tt")
        for (index, cell) in cells.enumerated() {
            let indexMatch = Index(rawValue: index)!

            switch indexMatch {
            case .SLN, .course, .type, .credits, .title:
                guard let cellText = cell.text?.trimmingCharacters(in: CharacterSet.whitespaces) else {
                    throw CourseFactoryError.generalParseError
                }
                switch indexMatch {
                case .SLN:
                    builder.SLN = parseSLN(cellText)
                case .course:
                    builder.course = cellText
                case .type:
                    builder.type = Course.CourseType(rawValue: cellText)
                case .credits:
                    builder.credits = Double(cellText)
                case .title:
                    builder.title = cellText
                default:
                    throw CourseFactoryError.generalParseError
                }
            case .days, .time, .location, .instructor:
                guard let rawLines = cell.innerHTML?.components(separatedBy: "<br>") else {
                    throw CourseFactoryError.generalParseError
                }

                let lines = try rawLines.map({ (line) -> String in
                    guard
                        let doc = try? Kanna.HTML(html: line, encoding: String.Encoding.utf8),
                        let text = doc.text
                        else {
                            throw CourseFactoryError.generalParseError
                    }

                    return text
                })

                switch indexMatch {
                case .days:
                    builder.daysList = lines
                case .time:
                    builder.timesList = lines
                case .location:
                    builder.locations = lines
                case .instructor:
                    builder.instructors = lines
                default:
                    throw CourseFactoryError.generalParseError
                }
            case .grading:
                break
            }
        }

        return try builder.build()
    }

    static func parseSLN(_ rawSLN: String?) -> Int? {
        guard let rawSLN = rawSLN else {
            return nil
        }
        let trimmedSLN = String(rawSLN.prefix(5))
        guard trimmedSLN.count == 5 else {
            return nil
        }
        return Int(trimmedSLN)
    }
}
