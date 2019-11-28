// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation
import GRDB

/// Exposes the notes of a Deck in an observable way.
public final class ObservableDeck: ObservableObject {
  public typealias NoteFactory = () -> (Note, NoteModel)?

  public init(
    database: CollectionDatabase,
    deckID: Int
  ) {
    self.database = database
    self.deckID = deckID
  }

  /// The underlying database.
  public let database: CollectionDatabase

  /// The deck we are viewing
  public let deckID: Int

  /// The query.
  public private(set) lazy var query: QueryInterfaceRequest<Note> = {
    let ids = noteModels.map { $0.id }
    return Note.filter(ids.contains(Column("mid")))
  }()

  /// The actual notes.
  @Published public private(set) var notes: [Note] = []

  /// All note models associated with this deck.
  public private(set) lazy var noteModels: [NoteModel] = {
    database.noteModels.compactMap { tuple in
      let (_, value) = tuple
      if value.deckID == deckID {
        return value
      } else {
        return nil
      }
    }
  }()

  /// Fetches the notes.
  @discardableResult
  public func fetch(completion: ((Result<[Note], Error>) -> Void)? = nil) -> Self {
    database.dbQueue!.asyncRead { databaseResult in
      let queryResult = databaseResult.flatMap { db in
        Result { try self.query.fetchAll(db) }
      }
      self.updateNotes(queryResult, completion: completion)
    }
    return self
  }

  /// Updates a note.
  public func updateNote(_ note: Note, completion: ((Result<[Note], Error>) -> Void)? = nil) {
    database.dbQueue!.asyncWrite({ db -> [Note] in
      try note.update(db)
      return try self.query.fetchAll(db)
    }, completion: { _, result in
      self.updateNotes(result, completion: completion)
    })
  }

  public func insertNote(_ note: Note, model: NoteModel, completion: ((Result<[Note], Error>) -> Void)? = nil) {
    guard
      let deckModel = database.deckModels[deckID],
      let deckConfig = database.deckConfigs[deckModel.configID]
    else {
      assertionFailure()
      return
    }
    database.dbQueue!.asyncWrite({ db -> [Note] in
      // Create a mutable copy.
      var note = note
      let now = Date().timeIntervalSince1970
      var newID = Int(floor(now * 1000)) // Start with integer milliseconds since the epoch
      while try Note.filter(key: newID).fetchCount(db) != 0 {
        newID += 1
      }
      note.id = newID
      note.modifiedTimestampSeconds = Int(floor(now))
      try note.insert(db)

      // Now save the cards for this note.
      newID += 1
      for card in note.cards(model: model) {
        var card = card
        while try Card.filter(key: newID).fetchCount(db) != 0 {
          newID += 1
        }
        card.id = newID
        card.deckID = self.deckID
        card.modificationTimeSeconds = Int(floor(now))
        card.due = note.id
        card.factor = deckConfig.new.initialFactor
        try card.insert(db)
        newID += 1
      }
      return try self.query.fetchAll(db)
    }, completion: { _, result in
      self.updateNotes(result, completion: completion)
    })
  }

  public func deleteNotes(_ notes: [Note], completion: ((Result<[Note], Error>) -> Void)? = nil) {
    database.dbQueue!.asyncWrite({ db -> [Note] in
      for note in notes {
        try Card.filter(Column("nid") == note.id).deleteAll(db)
      }
      try Note.deleteAll(db, keys: notes.map { $0.id })
      return try self.query.fetchAll(db)
    }, completion: { _, result in
      self.updateNotes(result, completion: completion)
    })
  }
}

private extension ObservableDeck {
  /// Updates the notes array with a new result.
  private func updateNotes(
    _ result: Result<[Note], Error>,
    completion: ((Result<[Note], Error>) -> Void)?
  ) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.updateNotes(result, completion: completion)
      }
      return
    }
    completion?(result)
    switch result {
    case .success(let notes):
      self.notes = notes
    case .failure(let error):
      logger.error("Error updating notes: \(error)")
    }
  }
}
