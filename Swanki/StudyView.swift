// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

struct StudyView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase
  let deckId: Int

  var body: some View {
    let card = cards.first
    let note = card.flatMap { try? collectionDatabase.fetchNote(id: $0.noteID) }
    let fieldViews = note?.fieldsArray.map { Text($0) } ?? []
    return VStack {
      Text(card.flatMap({ "\($0.id)" }) ?? "No card")
      ForEach(0..<fieldViews.count) {
        fieldViews[$0]
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
}
