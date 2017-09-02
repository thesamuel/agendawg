//
//  CourseTableViewCell.swift
//  Agendawg
//
//  Created by Sam Gehman on 9/1/17.
//  Copyright © 2017 Sam Gehman. All rights reserved.
//

import UIKit

class CourseTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var emojiLabel: UILabel!

    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    var detail: String? {
        get {
            return detailLabel.text
        }
        set {
            detailLabel.text = newValue
        }
    }

    var emoji: Course.Emoji? {
        get {
            if let text = emojiLabel.text{
                return Course.Emoji(rawValue: text)
            }
            return nil
        }
        set {
            emojiLabel.text = newValue?.rawValue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
