// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

struct StudyView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase
  let deckId: Int

  var body: some View {
    let properties = cards
      .compactMap { try? cardViewProperties(for: $0) }
      .prefix(1)
    return VStack {
      ForEach(properties) {
        CardView(properties: $0)
      }
    }
  }

  var cards: [Card] {
    do {
      return try collectionDatabase.fetchNewCards(from: deckId)
    } catch {
      logger.error("Unexpected error getting cards: \(error)")
      return []
    }
  }

  private func cardViewProperties(for card: Card) throws -> CardView.Properties {
    guard
      let note = try collectionDatabase.fetchNote(id: card.noteID)
    else {
      throw CollectionDatabase.Error.unknownNote(noteID: card.noteID)
    }
    guard let model = collectionDatabase.noteModels[note.modelID] else {
      throw CollectionDatabase.Error.unknownNoteModel(modelID: note.modelID)
    }
    return CardView.Properties(card: card, model: model, note: note, baseURL: collectionDatabase.url)
  }
}
