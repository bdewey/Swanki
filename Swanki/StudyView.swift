// Copyright © 2019-present Brian Dewey.

import Anki
import SpacedRepetitionScheduler
import SwiftUI

struct StudyView: View {
  @ObservedObject var studySession: StudySession

  var body: some View {
    let cardProperties = studySession.cards.enumerated().compactMap { try? cardViewProperties(for: $1, stackIndex: $0) }
    return ZStack {
      Text("You are done!").font(.largeTitle)
      ForEach(cardProperties.reversed()) { properties in
        CardView(properties: properties, didSelectAnswer: processAnswer)
          .scaleEffect(1.0 - CGFloat(properties.stackIndex) * 0.1)
          .offset(x: 0.0, y: -1 * CGFloat(properties.stackIndex) * 24)
          .hidden(properties.stackIndex >= 3)
          .zIndex(-1 * Double(properties.stackIndex))
      }
    }
  }

  private func cardViewProperties(for card: Anki.Card, stackIndex: Int) throws -> CardView.Properties {
    guard
      let note = try studySession.collectionDatabase.fetchNote(id: card.noteID)
    else {
      throw CollectionDatabase.Error.unknownNote(noteID: card.noteID)
    }
    guard let model = studySession.collectionDatabase.noteModels[note.modelID] else {
      throw CollectionDatabase.Error.unknownNoteModel(modelID: note.modelID)
    }
    guard
      let deckModel = studySession.collectionDatabase.deckModels[card.deckID],
      let config = studySession.collectionDatabase.deckConfigs[deckModel.configID]
    else {
      throw CollectionDatabase.Error.unknownDeck(deckID: card.deckID)
    }
    let scheduler = SpacedRepetitionScheduler(config: config)
    let answers = scheduler.scheduleItem(scheduler.makeSchedulingItem(for: card))
    return CardView.Properties(
      card: card,
      stackIndex: stackIndex,
      answers: answers,
      model: model,
      note: note,
      baseURL: studySession.collectionDatabase.url
    )
  }

  private func processAnswer(_ answer: CardAnswer, studyTime: TimeInterval) {
    logger.info("Card answer = \(answer.localizedName)")
    do {
      try withAnimation(.easeInOut(duration: 0.5)) {
        try studySession.recordAnswer(answer, studyTime: studyTime)
      }
    } catch {
      logger.error("Unexpected error recording answer: \(error)")
    }
  }
}

private extension View {
  func hidden(_ hide: Bool) -> some View {
    if hide {
      AnyView(hidden())
    } else {
      AnyView(self)
    }
  }
}
