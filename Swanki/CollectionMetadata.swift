// Copyright © 2019-present Brian Dewey.

import Foundation
import GRDB

public struct CollectionMetadata: Codable, FetchableRecord, PersistableRecord {
  public enum Error: Swift.Error {
    case cannotConvertKeyToInt(String)
  }

  public static var databaseTableName: String { "col" }
  public let id: Int
  public let models: String
  public let dconf: String
  public let decks: String

  public func loadModels() throws -> [Int: NoteModel] {
    let decoder = JSONDecoder()
    let data = models.data(using: .utf8)!
    let keysAndValues = try decoder.decode([String: NoteModel].self, from: data)
      .map { key, value -> (key: Int, value: NoteModel) in
        guard let intKey = Int(key) else {
          throw Error.cannotConvertKeyToInt(key)
        }
        return (key: intKey, value: value)
      }
    return Dictionary(uniqueKeysWithValues: keysAndValues)
  }

  public func loadDeckConfigs() throws -> [Int: DeckConfig] {
    let data = dconf.data(using: .utf8)!
    return try JSONDecoder().decode([Int: DeckConfig].self, from: data)
  }

  public func loadDecks() throws -> [Int: DeckModel] {
    let data = decks.data(using: .utf8)!
    return try JSONDecoder().decode([Int: DeckModel].self, from: data)
  }
}

public struct NoteModel {
  public let id: Int
  public let name: String
  public let requirements: [TemplateRequirement]?
  public let css: String
  public let deckID: Int?
  public let fields: [NoteField]
  public let modelType: ModelType
  public let templates: [CardTemplate]

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case requirements = "req"
    case css
    case deckID = "did"
    case fields = "flds"
    case modelType = "type"
    case templates = "tmpls"
  }
}

public struct TemplateRequirement: Codable {
  public enum RequirementType: String, Codable {
    case none
    case all
    case any
  }

  public init(
    templateId: Int,
    requirementType: RequirementType,
    fields: [Int]
  ) {
    self.templateId = templateId
    self.requirementType = requirementType
    self.fields = fields
  }

  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    self.templateId = try container.decode(Int.self)
    self.requirementType = try container.decode(RequirementType.self)
    self.fields = try container.decode([Int].self)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(templateId)
    try container.encode(requirementType)
    try container.encode(fields)
  }

  public let templateId: Int
  public let requirementType: RequirementType
  public let fields: [Int]
}

extension NoteModel: Codable {
  enum NoteDecodingError: Error {
    case noId
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    // Anki sometimes stores id as a string, sometimes as an int. why?
    if let id = try? values.decode(Int.self, forKey: .id) {
      self.id = id
    } else {
      let idString = try values.decode(String.self, forKey: .id)
      if let id = Int(idString) {
        self.id = id
      } else {
        throw NoteDecodingError.noId
      }
    }
    self.name = try values.decode(String.self, forKey: .name)
    self.requirements = try values.decodeIfPresent([TemplateRequirement].self, forKey: .requirements)
    self.css = try values.decode(String.self, forKey: .css)
    self.deckID = try values.decode(Int?.self, forKey: .deckID)
    self.fields = try values.decode([NoteField].self, forKey: .fields)
    self.modelType = try values.decode(ModelType.self, forKey: .modelType)
    self.templates = try values.decode([CardTemplate].self, forKey: .templates)
  }
}

public struct CardTemplate: Codable {
  public let name: String
  public let afmt: String
  public let bafmt: String
  public let bqfmt: String
  public let ord: Int
  public let qfmt: String
}

public enum ModelType: Int, Codable {
  case standard = 0
  case cloze = 1
}

public struct NoteField: Codable {
  public let font: String
  public let name: String
  public let ord: Int
}

public struct DeckModel: Codable, Identifiable {
  public let id: Int
  public let name: String
  public let desc: String
  public let configID: Int

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case desc
    case configID = "conf"
  }
}
