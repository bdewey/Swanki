// Copyright © 2019 Brian's Brain. All rights reserved.

import Combine
import Foundation
import GRDB
import GRDBCombine
import Logging
import Zipper

/// Holds the database containing the Anki collection.
public final class CollectionDatabase: NSObject, ObservableObject {
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
    self.databaseURL = url.appendingPathComponent("collection.anki2")
  }

  /// The URL that holds the main database and all associated media
  public let url: URL

  /// The URL to the database within the the container
  public let databaseURL: URL

  /// Queue for performing database I/O operations.
  public var dbQueue: DatabaseQueue?

  /// If true, then this
  public var hasUnsavedChanges = false {
    didSet {
      assert(Thread.isMainThread)
      logger.info("collectionDatabase hasUnsavedChanges = \(hasUnsavedChanges)")
    }
  }

  private var isWriteable = true {
    didSet {
      assert(Thread.isMainThread)
      logger.info("collectionDatabase isWriteable = \(isWriteable)")
    }
  }

  private var databaseChangeObserver: AnyCancellable? {
    willSet {
      databaseChangeObserver?.cancel()
    }
  }

  public func openDatabase() throws {
    assert(Thread.isMainThread)
    precondition(dbQueue == nil)
    let coordinator = NSFileCoordinator()
    var coordinatorError: NSError?
    var result: Result<DatabaseQueue, Swift.Error>?
    coordinator.coordinate(readingItemAt: databaseURL, options: [], error: &coordinatorError) { coordinatedURL in
      result = Result {
        let fileQueue = try DatabaseQueue(path: coordinatedURL.path)
        let queue = try DatabaseQueue(path: ":memory:")
        try fileQueue.backup(to: queue)
        return queue
      }
    }

    if let coordinatorError = coordinatorError {
      throw coordinatorError
    }

    switch result {
    case .success(let memoryQueue):
      databaseChangeObserver = DatabaseRegionObservation(tracking: [Note.all(), LogEntry.all()])
        .publisher(in: memoryQueue)
        .receive(on: RunLoop.main)
        .map { [weak self] _ in self?.hasUnsavedChanges = true }
        .throttle(for: 10, scheduler: RunLoop.main, latest: true)
        .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
          self?.saveIfNeededAndLogError()
        })
      dbQueue = memoryQueue
    case .failure(let error):
      throw error
    case .none:
      throw Error.noDatabaseInPackage
    }
  }

  public func saveIfNeededAndLogError() {
    do {
      try saveIfNeeded()
    } catch {
      logger.error("collectionDatabase Unexpected error saving database: \(error)")
    }
  }

  public func saveIfNeeded() throws {
    assert(Thread.isMainThread)
    guard isWriteable, hasUnsavedChanges, let memoryDatabase = dbQueue else { return }
    var coordinatorError: NSError?
    var innerError: Swift.Error?
    NSFileCoordinator().coordinate(writingItemAt: databaseURL, options: [], error: &coordinatorError) { coordinatedURL in
      do {
        let fileQueue = try DatabaseQueue(path: coordinatedURL.path)
        try memoryDatabase.backup(to: fileQueue)
        hasUnsavedChanges = false
        logger.info("collectionDatabase Saved database")
      } catch {
        innerError = error
      }
    }
    if let coordinatorError = coordinatorError {
      throw coordinatorError
    }
    if let innerError = innerError {
      throw innerError
    }
  }

  /// Debug routine: Deletes everything that's currently in the container.
  public func emptyContainer() throws {
    precondition(dbQueue == nil)
    let items = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])) ?? []
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
        .filter(Column("queue") == Card.CardQueue.new.rawValue)
        .order(Column("due").asc)
        .limit(limit)
        .fetchAll(db)
    }
  }

  public func fetchLearningCards(from deckID: Int) throws -> [Card] {
    let dueTime = Date().secondsRelativeFormat
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
    let dueTime = Date().dayRelativeFormat
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

  public func recordAnswer(_ answer: CardAnswer, for card: Card, studyTime: TimeInterval) throws {
    guard
      let model = deckModels[card.deckID],
      let config = deckConfigs[model.configID]
    else {
      throw Error.unknownDeck(deckID: card.deckID)
    }
    let scheduler = SpacedRepetitionScheduler(config: config)
    let item = scheduler.makeSchedulingItem(for: card)
    let nextItem = scheduler.scheduleItem(item)[answer]!
    var newCard = card
    scheduler.applyItem(nextItem, to: &newCard)
    try dbQueue?.write { db in
      try newCard.update(db)
      let logEntry = LogEntry(now: Date(), oldCard: card, newCard: newCard, answer: answer, studyTime: studyTime)
      try logEntry.insert(db)
    }
  }
}

// MARK: - NSFilePresenter
extension CollectionDatabase: NSFilePresenter {
  public var presentedItemURL: URL? {
    databaseURL
  }

  public var presentedItemOperationQueue: OperationQueue {
    OperationQueue.main
  }

  public func savePresentedItemChanges(completionHandler: @escaping (Swift.Error?) -> Void) {
    do {
      try saveIfNeeded()
      completionHandler(nil)
    } catch {
      completionHandler(error)
    }
  }

  public func relinquishPresentedItem(toReader reader: @escaping ((() -> Void)?) -> Void) {
    isWriteable = false
    reader({
      self.isWriteable = true
    })
  }

  public func relinquishPresentedItem(toWriter writer: @escaping ((() -> Void)?) -> Void) {
    isWriteable = false
    writer({
      self.isWriteable = true
    })
  }

  public func presentedItemDidChange() {
    // TODO: Check if this was a content change or an attribute change
    try? openDatabase()
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
