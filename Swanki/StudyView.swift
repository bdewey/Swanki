// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

struct StudyView: View {
  @ObservedObject var studySequence: StudySequenceWrapper

  var body: some View {
    let properties = studySequence.currentCard.flatMap { try? cardViewProperties(for: $0) }
    return VStack {
      if properties != nil {
        CardView(properties: properties!, didSelectAnswer: processAnswer)
      } else {
        EmptyView()
      }
    }
  }

  private func cardViewProperties(for card: Card) throws -> CardView.Properties {
    guard
      let note = try studySequence.collectionDatabase.fetchNote(id: card.noteID)
    else {
      throw CollectionDatabase.Error.unknownNote(noteID: card.noteID)
    }
    guard let model = studySequence.collectionDatabase.noteModels[note.modelID] else {
      throw CollectionDatabase.Error.unknownNoteModel(modelID: note.modelID)
    }
    guard
      let deckModel = studySequence.collectionDatabase.deckModels[card.deckID],
      let config = studySequence.collectionDatabase.deckConfigs[deckModel.configID]
    else {
      throw CollectionDatabase.Error.unknownDeck(deckID: card.deckID)
    }
    let scheduler = SpacedRepetitionScheduler(config: config)
    let answers = scheduler.scheduleItem(scheduler.makeSchedulingItem(for: card))
    return CardView.Properties(card: card, answers: answers, model: model, note: note, baseURL: studySequence.collectionDatabase.url)
  }

  private func processAnswer(_ answer: CardAnswer, studyTime: TimeInterval) {
    logger.info("Card answer = \(answer)")
    if let card = studySequence.currentCard {
      do {
        try studySequence.collectionDatabase.recordAnswer(answer, for: card, studyTime: studyTime)
      } catch {
        logger.error("Unexpected error recording answer: \(error)")
      }
    }
    studySequence.advance()
  }
}

public class StudySequenceWrapper: ObservableObject {
  public init(collectionDatabase: CollectionDatabase, deckId: Int) {
    self.collectionDatabase = collectionDatabase
    self.deckID = deckId
    let studySequence = StudySequence(collectionDatabase: collectionDatabase, decks: [deckId])
    self.iterator = studySequence.makeIterator()
    self.currentCard = iterator.next()
  }

  public let collectionDatabase: CollectionDatabase
  public let deckID: Int
  private var iterator: StudySequence.Iterator
  @Published private(set) var currentCard: Card?

  func advance() {
    currentCard = iterator.next()
    logger.debug("Card id is now \(currentCard?.id ?? -1)")
  }
}
