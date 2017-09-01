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

    static let startDate = Date(dateString: "September 27, 2017", format: "MMMM d, yyyy")
    static let endDate = Date(dateString: "December 8, 2017", format: "MMMM d, yyyy")
    
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

    enum CourseError: Error {
        case InvalidTimeFormat(String)
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
        let time = row[Index.time.rawValue]
        let days = row[Index.days.rawValue]
        let dates = Course.dates(forTime: time, days: days)

        // Optional properties
        credits = Double(row[Index.credits.rawValue])

        let location = row[Index.location.rawValue]
        self.location = !location.isEmpty ? location : nil

        let instructor = row[Index.instructor.rawValue]
        self.instructor = !instructor.isEmpty ? instructor : nil
    }

}

extension Course {

    enum Weekday: Int {
        case monday = 2
        case tuesday
        case wednesday
        case thursday
        case friday
    }

    static let dayChunk = TimeChunk(seconds: 0, minutes: 0, hours: 0, days: 1, weeks: 0, months: 0, years: 0)

    static func dates(forTime time: String, days: String) -> [(Date, Date)] {
        let formattedTime = formatTime(time: time)
        guard formattedTime.count == 2 else {
            fatalError()
        }

        let formattedWeekdays = weekdays(for: days)
        guard formattedWeekdays.count > 0 else {
            fatalError()
        }

        return formattedWeekdays.map { (weekday) -> (Date, Date) in
            let adjustedDates = formattedTime.map({ (date) -> Date in
                let adjustmentDate = firstWeekday(weekday: weekday, date: startDate)
                var date = date
                date.day(adjustmentDate.day)
                date.month(adjustmentDate.month)
                date.year(adjustmentDate.year)
                return date
            })
            return (adjustedDates[0], adjustedDates[1])
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
        dateFormatter.locale = Locale.init(identifier: "en_US")
        return formattedTime.map { (time) -> Date in
            guard let date = dateFormatter.date(from: time) else {
                fatalError()
            }
            return date
        }
    }

}
