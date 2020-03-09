//
//  User.swift
//  Crosstalk
//
//  Created by Scott Gardner on 1/20/20.
//  Copyright © 2020 Scott Gardner. All rights reserved.
//

import UIKit

class User {
    static let local = User()
    
    let id = UUID()
    var name: String { UIDevice.current.name }
    
    private init() { }
}
