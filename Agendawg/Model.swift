//
//  Model.swift
//  Agendawg
//
//  Created by Sam Gehman on 8/31/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit
import Kanna

class Model: NSObject {

    static let registrationTableXpath = "//form/table/tbody/tr/td/tt"
    var courses: [Course]?

    func parseHTML(html: String) -> Bool {
        guard let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) else {
            return false
        }

        let registrationTableElements = doc.xpath(Model.registrationTableXpath)
        guard registrationTableElements.count > 0 else {
            return false
        }

        var rows = [[String]]()
        var currentRow = [String]()
        for element in registrationTableElements {
            if currentRow.count >= 10 {
                rows.append(currentRow)
                currentRow = [String]()
            }

            guard let text = element.text else {
                print("Error parsing HTML.")
                return false
            }

            let trimmed = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            currentRow.append(trimmed)
        }

        self.courses = rows.reduce([Course]()) { (result, row) -> [Course] in
            guard let course = Course(row: row) else {
                fatalError()
            }
            return result + [course]
        }
        
        guard let courseCount = self.courses?.count,
            courseCount > 0 else {
                return false
        }

        print("Courses parsed.")
        return true
    }

}
