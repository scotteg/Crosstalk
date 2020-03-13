//
//  TranslationResponse.swift
//  Crosstalk
//
//  Created by Scott Gardner on 2/6/20.
//  Copyright © 2020 Scott Gardner. All rights reserved.
//

import Foundation

struct TranslationResponse: Codable {
  enum CodingKeys: String, CodingKey {
    case languageCode = "lang", translations = "text"
  }
  
  let languageCode: String
  let translations: [String]
}
