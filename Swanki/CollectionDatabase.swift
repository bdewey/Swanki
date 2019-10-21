// Copyright © 2019 Brian's Brain. All rights reserved.

import Combine
import Foundation
import GRDB
import Logging
import Zipper

/// Holds the database containing the Anki collection.
public final class CollectionDatabase: ObservableObject {
  enum Error: Swift.Error {
    case couldNotLoadPackage
    case noDatabaseInPackage
    case unknownDeck(deckID: Int)
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
    for entry in zipper {
      logger.debug("\(entry.path)")
      if entry.path == "collection.anki2" {
        _ = try zipper.extract(entry, to: url.appendingPathComponent("collection.anki2"))
        return
      }
    }
    throw Error.noDatabaseInPackage
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
}
