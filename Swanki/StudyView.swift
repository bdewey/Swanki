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
    return CardView.Properties(card: card, model: model, note: note, baseURL: studySequence.collectionDatabase.url)
  }

  private func processAnswer(_ answer: CardAnswer) {
    logger.info("Card answer = \(answer)")
    if let card = studySequence.currentCard {
      do {
        try studySequence.collectionDatabase.recordAnswer(answer, for: card)
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
    let studySequence = StudySequence(collectionDatabase: collectionDatabase, decks: [deckId])
    self.iterator = studySequence.makeIterator()
    self.currentCard = iterator.next()
  }

  public let collectionDatabase: CollectionDatabase
  private var iterator: StudySequence.Iterator
  @Published private(set) var currentCard: Card?

  func advance() {
    currentCard = iterator.next()
    logger.debug("Card id is now \(currentCard?.id ?? -1)")
  }
}
