// Copyright © 2019 Brian's Brain. All rights reserved.

import Combine
import Foundation
import GRDB
import Logging
import Zipper

/// Holds the database containing the Anki collection.
public final class CollectionDatabase: ObservableObject {
  public enum Error: Swift.Error {
    case couldNotLoadPackage
    case noDatabaseInPackage
    case unknownDeck(deckID: Int)
    case unknownNote(noteID: Int)
    case unknownNoteModel(modelID: Int)
  }

  /// Designated initializer.
  /// - parameter url: The container URL for the main database and all associated media.
  public init(url: URL) {
    self.url = url
  }

  /// The URL that holds the main database and all associated media
  public let url: URL

  /// Queue for performing database I/O operations.
  public var dbQueue: DatabaseQueue?

  public func openDatabase() throws {
    precondition(dbQueue == nil)
    dbQueue = try DatabaseQueue(path: url.appendingPathComponent("collection.anki2").path)
  }

  /// Debug routine: Deletes everything that's currently in the container.
  public func emptyContainer() throws {
    precondition(dbQueue == nil)
    let items = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
    for item in items {
      try FileManager.default.removeItem(at: item)
    }
  }

  /// Imports a "apkg" package into this database.
  /// - note: Currently this just copies the collection.anki2 entry out of the file and overwrites the container database with it.
  public func importPackage(_ packageUrl: URL) throws {
    guard let zipper = Zipper.read(at: packageUrl) else {
      logger.error("Could not open zip file at \(packageUrl)")
      throw Error.couldNotLoadPackage
    }
    let mediaMap = zipper.mediaMap
    logger.info("Media map: \(mediaMap)")
    var didExtractDatabase = false
    for entry in zipper {
      logger.debug("\(entry.path)")
      if entry.path == "collection.anki2" {
        _ = try zipper.extract(entry, to: url.appendingPathComponent("collection.anki2"))
        didExtractDatabase = true
      }
      if let destinationMedia = mediaMap[entry.path] {
        logger.info("Extracting \(entry.path) to \(destinationMedia)")
        _ = try zipper.extract(entry, to: url.appendingPathComponent(destinationMedia))
      }
    }
    if !didExtractDatabase {
      throw Error.noDatabaseInPackage
    }
  }

  public private(set) var noteModels: [Int: NoteModel] = [:]
  public private(set) var deckModels: [Int: DeckModel] = [:]
  public private(set) var deckConfigs: [Int: DeckConfig] = [:]

  public func fetchMetadata() throws {
    guard let collectionMetadata = try dbQueue!.read({ db -> CollectionMetadata? in
      try CollectionMetadata.fetchOne(db)
    }) else {
      return
    }
    let noteModels = try collectionMetadata.loadModels()
    let deckModels = try collectionMetadata.loadDecks()
    let deckConfigs = try collectionMetadata.loadDeckConfigs()

    objectWillChange.send()
    self.noteModels = noteModels
    self.deckModels = deckModels
    self.deckConfigs = deckConfigs
  }

  /// Cache of all notes in the database. Update by calling `fetchNotes()`
  @Published public private(set) var notes: [Note] = []

  /// Fetches all notes in the database and stores them in `notes`
  public func fetchNotes() throws {
    notes = try dbQueue!.read { db -> [Note] in
      try Note.fetchAll(db)
    }
  }

  public func fetchNote(id: Int) throws -> Note? {
    try dbQueue!.read { db -> Note? in
      try Note
        .filter(Column("id") == id)
        .fetchOne(db)
    }
  }

  public func fetchNewCards(from deckID: Int) throws -> [Card] {
    let limit = try newCardLimit(for: deckID)
    return try dbQueue!.read { db -> [Card] in
      try Card
        .filter(Column("did") == deckID)
        .order(Column("due").asc)
        .limit(limit)
        .fetchAll(db)
    }
  }

  public func fetchLearningCards(from deckID: Int) throws -> [Card] {
    let dueTime = Int(round(Date().timeIntervalSinceReferenceDate))
    return try dbQueue!.read { db -> [Card] in
      try Card
        .filter(Column("did") == deckID)
        .filter(Column("queue") == Card.CardQueue.learning.rawValue || Column("queue") == Card.CardQueue.futureLearning.rawValue)
        .filter(Column("due") <= dueTime)
        .order(Column("due").asc)
        .fetchAll(db)
    }
  }

  public func fetchReviewCards(from deckID: Int) throws -> [Card] {
    let limit = try reviewCardLimit(for: deckID)
    let dueTime = Int(round(Date().timeIntervalSinceReferenceDate))
    return try dbQueue!.read { db -> [Card] in
      try Card
        .filter(Column("did") == deckID)
        .filter(Column("queue") == Card.CardQueue.due.rawValue)
        .filter(Column("due") <= dueTime)
        .order(Column("due").asc)
        .limit(limit)
        .fetchAll(db)
    }
  }

  /// How many new cards per day we are supposed to study from deck `deckID`
  public func newCardLimit(for deckID: Int) throws -> Int {
    guard
      let deck = deckModels[deckID],
      let config = deckConfigs[deck.configID]
    else {
      throw Error.unknownDeck(deckID: deckID)
    }
    return config.new.perDay
  }

  /// How many new cards per day we are supposed to study from deck `deckID`
  public func reviewCardLimit(for deckID: Int) throws -> Int {
    guard
      let deck = deckModels[deckID],
      let config = deckConfigs[deck.configID]
    else {
      throw Error.unknownDeck(deckID: deckID)
    }
    return config.rev.perDay
  }

  public func recordAnswer(_ answer: CardAnswer, for card: Card) throws {
    guard
      let model = deckModels[card.deckID],
      let config = deckConfigs[model.configID]
    else {
      throw Error.unknownDeck(deckID: card.deckID)
    }
    let scheduler = SpacedRepetitionScheduler(config: config)
    let item = scheduler.makeSchedulingItem(for: card)
    let nextItem = scheduler.scheduleItem(item)[answer]!
    var card = card
    scheduler.applyItem(nextItem, to: &card)
    try dbQueue?.write { db in
      try card.update(db)
    }
  }
}

private extension Zipper {
  var mediaMap: [String: String] {
    do {
      var mediaEntries: [String: String] = [:]
      if let mediaMapEntry = self["media"] {
        _ = try extract(mediaMapEntry) { data in
          mediaEntries = try JSONDecoder().decode([String: String].self, from: data)
        }
      }
      return mediaEntries
    } catch {
      logger.error("Unexpected error extracting media map from archive: \(error)")
      return [:]
    }
  }
}

private extension CardAnswer {
  var factor: Int {
    switch self {
    case .again:
      return 0
    case .hard:
      return -150
    case .good:
      return 0
    case .easy:
      return 150
    }
  }
}
