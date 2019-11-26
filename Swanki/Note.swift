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
  public var encodedFields: String

  private static let fieldSeparator: Character = "\u{1F}"

  public var fieldsArray: [String] {
    encodedFields.split(separator: Self.fieldSeparator).map { String($0) }
  }

  public mutating func setField(at index: Int, to value: String) {
    var existingFields = encodedFields.split(separator: Self.fieldSeparator)
    existingFields[index] = value[value.startIndex...]
    encodedFields = existingFields.joined(separator: String(Self.fieldSeparator))
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
