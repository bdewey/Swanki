// Copyright © 2019-present Brian Dewey.

import Foundation
import GRDB

public struct Note: Codable, FetchableRecord, PersistableRecord, Identifiable {
  public static var databaseTableName: String { "notes" }
  public var id: Int
  public let guid: String
  public let modelID: Int
  public var modifiedTimestampSeconds: Int
  public var usn: Int
  public var tags: String
  public var encodedFields: String

  // We need to have all database fields represented even if we don't use them.

  public var sortFields: String = ""
  public let csum: Int = 0
  public let flags = 0
  public let data = ""

  private static let fieldSeparator: Character = "\u{1F}"

  public var fieldsArray: [String] {
    encodedFields.split(separator: Self.fieldSeparator, omittingEmptySubsequences: false).map { String($0) }
  }

  public mutating func setField(at index: Int, to value: String) {
    var existingFields = encodedFields.split(separator: Self.fieldSeparator, omittingEmptySubsequences: false)
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
    case sortFields = "sfld"
    case csum
    case flags
    case data
  }
}

public extension Note {
  static func makeEmptyNote(modelID: Int, fieldCount: Int) -> Note {
    Note(
      id: 0,
      guid: UUID().uuidString,
      modelID: modelID,
      modifiedTimestampSeconds: 0,
      usn: 0,
      tags: "",
      encodedFields: String(repeating: fieldSeparator, count: fieldCount - 1)
    )
  }

  /// Makes new Card structures from this note.
  func cards(model: NoteModel) -> [Card] {
    model.templates.map { template -> Card in
      Card(noteID: self.id, deckID: model.deckID ?? 312, templateIndex: template.ord)
    }
  }
}
