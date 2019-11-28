// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation
import GRDB

/// Holds the results of a SELECT of Note data from a CollectionDatabase.
public final class NotesResults: ObservableObject {
  public init(
    database: CollectionDatabase,
    query: QueryInterfaceRequest<Note>,
    noteFactory: @escaping () -> Note
  ) {
    self.database = database
    self.query = query
    self.noteFactory = noteFactory
  }

  /// The underlying database.
  public let database: CollectionDatabase

  /// The query.
  public let query: QueryInterfaceRequest<Note>

  /// A factory block for creating new notes relevant to these results.
  public let noteFactory: () -> Note

  /// The actual notes.
  @Published public private(set) var notes: [Note] = []

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

  public func insertNote(_ note: Note, completion: ((Result<[Note], Error>) -> Void)? = nil) {
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
      return try self.query.fetchAll(db)
    }, completion: { _, result in
      self.updateNotes(result, completion: completion)
    })
  }

  public func deleteNotes(_ notes: [Note], completion: ((Result<[Note], Error>) -> Void)? = nil) {
    database.dbQueue!.asyncWrite({ db -> [Note] in
      try Note.deleteAll(db, keys: notes.map({ $0.id }))
      return try self.query.fetchAll(db)
    }, completion: { _, result in
      self.updateNotes(result, completion: completion)
    })
  }
}

private extension NotesResults {
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
