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
    }

    static func makeCourse(from row: XMLElement) throws -> Course? {
        guard
            let rowHtml = row.innerHTML,
            let rowDoc = try? Kanna.HTML(html: rowHtml, encoding: String.Encoding.utf8)
            else {
                throw CourseFactoryError.generalParseError
        }

        // Build course
        let builder = CourseBuilder()
        let cells = rowDoc.css(Registration.cellSelector)
        for (index, cell) in cells.enumerated() {
            guard let regIndex = Registration.Index(rawValue: index) else {
                throw CourseFactoryError.generalParseError
            }

            switch regIndex {
            case .SLN, .course, .type, .credits, .title:
                try parseSingleLineCell(builder: builder, index: regIndex, cell: cell)
            case .days, .time, .location, .instructor:
                try parseMultiLineCell(builder: builder, index: regIndex, cell: cell)
            case .grading:
                break
            }
        }

        return try? builder.build()
    }

    static func parseSingleLineCell(builder: CourseBuilder, index: Registration.Index,
                                    cell: XMLElement) throws {
        // Trim whitespace
        guard let cellText = cell.text?.trimmingCharacters(in: CharacterSet.whitespaces) else {
            throw CourseFactoryError.generalParseError
        }

        switch index {
        case .SLN:
            builder.SLN = cellText
        case .course:
            builder.course = cellText
        case .type:
            builder.type = Registration.CourseType(rawValue: cellText)
        case .credits:
            builder.credits = cellText
        case .title:
            builder.title = cellText
        default:
            throw CourseFactoryError.generalParseError
        }
    }

    static func parseMultiLineCell(builder: CourseBuilder, index: Registration.Index,
                                      cell: XMLElement) throws {
        // Split lines
        guard let rawLines = cell.innerHTML?.components(separatedBy: Registration.lineBreak) else {
            throw CourseFactoryError.generalParseError
        }

        // Parse each line's HTML individually
        let lines = try rawLines.map({ (line) -> String in
            guard
                let doc = try? Kanna.HTML(html: line, encoding: String.Encoding.utf8),
                let text = doc.text?.trimmingCharacters(in: CharacterSet.whitespaces)
                else {
                    throw CourseFactoryError.generalParseError
            }
            return text
        })

        switch index {
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
    }
}
