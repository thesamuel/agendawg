//
//  Course.swift
//  Agendawg
//
//  Created by Sam Gehman on 8/31/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import Foundation

struct Course {
    enum CourseType: String {
        case lecture = "LC"
        case quiz = "QZ"
    }

    enum Index: Int {
        case SLN = 0    // 0. "10290"
        case course     // 1. "ANTH 101 A"
        case type       // 2. "LC"
        case credits    // 3. "5.0"
        case grading    // 4. "standard\nS/NS\n"
        case title      // 5. "EXPLORING SOC ANTHR"
        case days       // 6. "MW"
        case time       // 7. "130- 320" or "1030-1120"
        case location   // 8. "JHN 102"
        case instructor // 9. "Perez,Michael Vincente"
    }

    let SLN: Int
    let course: String
    let title: String
    let type: CourseType

    let credits: Double? // Optional
    let location: String? // Optional
    let instructor: String? // Optional

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

        // Create an event from the days and time
        let days = row[Index.days.rawValue]
        let time = row[Index.time.rawValue]

        // Optional properties
        credits = Double(row[Index.credits.rawValue])

        let location = row[Index.location.rawValue]
        self.location = !location.isEmpty ? location : nil

        let instructor = row[Index.instructor.rawValue]
        self.instructor = !instructor.isEmpty ? instructor : nil
    }

//    static func date(fromDays: String, time: String) -> Date {
//
//    }
}


