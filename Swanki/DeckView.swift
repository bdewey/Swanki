// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

struct DeckView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase

  var body: some View {
    NavigationView {
      List(sortedDecks) { deckModel in
        NavigationLink(destination: StudyView(deckId: deckModel.id)) {
          Text(deckModel.name)
        }
      }
      .navigationBarTitle("Decks")
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }

  var sortedDecks: [DeckModel] {
    Array(collectionDatabase.deckModels.values.sorted(by: { $0.name < $1.name }))
  }
}
