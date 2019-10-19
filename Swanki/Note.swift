// Copyright © 2019 Brian's Brain. All rights reserved.

import Combine
import Foundation
import GRDB

public struct Note: Codable, FetchableRecord, PersistableRecord, Identifiable {
  public static var databaseTableName: String { "notes" }
  public let id: Int
  public let guid: String
  public let modelID: Int
  public let modifiedTimestampSeconds: Int
  public let usn: Int
  public let tags: String
  public let encodedFields: String

  public var fieldsArray: [String] {
    encodedFields.split(separator: "\u{1F}").map { String($0) }
  }

  enum CodingKeys: String, CodingKey {
    case id
    case guid
    case modelID = "mid"
    case modifiedTimestampSeconds = "mod"
    case usn
    case tags
    case encodedFields = "flds"
  }
}
