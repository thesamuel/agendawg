//
//  Constants.swift
//  Agendawg
//
//  Created by Sam Gehman on 9/1/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import Foundation

struct Constants {

    static let startDate = Date(dateString: "January 3, 2018", format: "MMMM d, yyyy")
    static let endDate = Date(dateString: "March 9, 2018", format: "MMMM d, yyyy")

//    static let startDate = Date(dateString: "September 27, 2017", format: "MMMM d, yyyy")
//    static let endDate = Date(dateString: "December 8, 2017", format: "MMMM d, yyyy")

//    static let registrationURL = URL(string: "https://sdb.admin.uw.edu/students/uwnetid/register.asp")!
    static let registrationURL = URL(string: "http://localhost:8888/Registration.html")!

}
