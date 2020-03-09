//
//  Message.swift
//  Crosstalk
//
//  Created by Scott Gardner on 1/20/20.
//  Copyright © 2020 Scott Gardner. All rights reserved.
//

import Foundation

struct Message: Codable, Identifiable {
    let id = UUID()
    let username: String
    let value: String
    let timestamp: String
    
    var isFromLocalUser: Bool { username == User.local.name }
}
