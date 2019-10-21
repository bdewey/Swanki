// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

struct StudyView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase
  let deckId: Int

  var body: some View {
    List(cards) { card in
      Text("\(card.id)")
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
