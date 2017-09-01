//
//  Model.swift
//  Agendawg
//
//  Created by Sam Gehman on 8/31/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit
import Alamofire
import Kanna

class Model: NSObject {

    static let registrationTableXpath = "//form/table/tbody/tr/td/tt"
    var courses: [Course]?

    func parseHTML(html: String) {
        guard let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) else {
            return
        }

        let registrationTableElements = doc.xpath(Model.registrationTableXpath)
        var rows = [[String]]()
        var currentRow = [String]()
        for element in registrationTableElements {
            if currentRow.count >= 10 {
                rows.append(currentRow)
                currentRow = [String]()
            }

            guard let text = element.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                print("error parsing HTML")
                return
            }

            currentRow.append(text)
        }

        self.courses = rows.reduce([Course]()) { (result, row) -> [Course] in
            guard let course = Course(row: row) else {
                    fatalError()
            }
            return result + [course]
        }
        
        if let courseCount = self.courses?.count,
            courseCount > 0 {
            print("done")
        }
    }

}
