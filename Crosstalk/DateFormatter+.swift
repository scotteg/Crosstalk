//
//  DateFormatter+.swift
//  Crosstalk
//
//  Created by Scott Gardner on 1/20/20.
//  Copyright © 2020 Scott Gardner. All rights reserved.
//

import Foundation

extension DateFormatter {
    convenience init(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) {
        self.init()
        self.dateStyle = dateStyle
        self.timeStyle = timeStyle
    }
}
