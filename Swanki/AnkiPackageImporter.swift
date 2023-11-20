// Copyright © 2019-present Brian Dewey.

import Anki
import Foundation
import GRDB
import os
import SwiftData
import Zipper

/// Imports an Anki package into the Swanki native SwiftData format.
///
/// - warning: Currently this ignores all customization in the Anki package. It does not import study history. It ignores the cards and assumes that any note that has two fields
/// is supposed to be a front + back template. Basically this is as dumb as can be to just allow importing of simple content to test & develop with.
public struct AnkiPackageImporter {
  public enum Error: Swift.Error {
    case couldNotLoadPackage
    case noDatabaseInPackage
    case unknownDeck(deckID: Int)
    case unknownNote(noteID: Int)
    case unknownNoteModel(modelID: Int)
  }

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AnkiPackageImporter")

  public let packageURL: URL
  public let modelContext: ModelContext

  public func importPackage() throws {
    guard let zipper = Zipper.read(at: packageURL) else {
      logger.error("Could not open zip file at \(packageURL)")
      throw Error.couldNotLoadPackage
    }
    var didExtractDatabase = false
    for entry in zipper {
      logger.debug("\(entry.path)")
      if entry.path == "collection.anki21" {
        let destinationURL = URL.temporaryDirectory.appending(components: UUID().uuidString, "collection.anki21", directoryHint: .notDirectory)
        logger.debug("Extracting Anki package to \(destinationURL)")
        _ = try zipper.extract(entry, to: destinationURL)
        try importPackage(at: destinationURL)
        didExtractDatabase = true
      }
    }
    if !didExtractDatabase {
      throw Error.noDatabaseInPackage
    }
  }

  private func importPackage(at url: URL) throws {
    let dbQueue = try DatabaseQueue(path: url.path)
    guard let collectionMetadata = try dbQueue.read({ db -> CollectionMetadata? in
      try CollectionMetadata.fetchOne(db)
    }) else {
      return
    }
    let deckModels = try collectionMetadata.loadDecks()

    // key == 1 means "default deck" that has no content
    for (key, deckModel) in deckModels where key != 1 {
      logger.debug("Importing deck \(deckModel.name)")
      let deck = Deck(name: deckModel.name)
      modelContext.insert(deck)
      let ankiNotes = try dbQueue.read { db in
        try fetchNotes(from: db, deckID: deckModel.id)
      }
      logger.debug("Found \(ankiNotes.count) note(s)")
      for ankiNote in ankiNotes {
        if ankiNote.fieldsArray.count == 2 {
          let note = deck.addNote {
            Note(modificationTime: Date(timeIntervalSince1970: TimeInterval(ankiNote.modifiedTimestampSeconds)), fields: ankiNote.fieldsArray)
          }
          note.addCard {
            Card(type: .frontThenBack)
          }
          note.addCard {
            Card(type: .backThenFront)
          }
        } else {
          logger.debug("Skipping note \(ankiNote.id) because it has \(ankiNote.fieldsArray.count) fields and we can only import 2")
        }
      }
    }
  }

  private func fetchNotes(from db: Database, deckID: Int) throws -> [Anki.Note] {
    let cards = try Anki.Card
      .select(Column("nid"), as: Int.self).distinct()
      .filter(Column("did") == deckID)
      .fetchAll(db)
    return try Anki.Note.filter(keys: cards).fetchAll(db)
  }
}
