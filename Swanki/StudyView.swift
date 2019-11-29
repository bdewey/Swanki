// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

struct StudyView: View {
  @ObservedObject var studySession: StudySession

  var body: some View {
    let properties = studySession.cards.first.flatMap { try? cardViewProperties(for: $0) }
    return VStack {
      if properties != nil {
        CardView(properties: properties!, didSelectAnswer: processAnswer)
      } else {
        Text("You are done!").font(.largeTitle)
      }
    }
    .animation(/*@START_MENU_TOKEN@*/.easeInOut/*@END_MENU_TOKEN@*/)
  }

  private func cardViewProperties(for card: Card) throws -> CardView.Properties {
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
    return CardView.Properties(card: card, answers: answers, model: model, note: note, baseURL: studySession.collectionDatabase.url)
  }

  private func processAnswer(_ answer: CardAnswer, studyTime: TimeInterval) {
    logger.info("Card answer = \(answer)")
    do {
      try studySession.recordAnswer(answer, studyTime: studyTime)
    } catch {
      logger.error("Unexpected error recording answer: \(error)")
    }
  }
}
