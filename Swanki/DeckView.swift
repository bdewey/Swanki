// Copyright © 2019 Brian's Brain. All rights reserved.

import GRDB
import SwiftUI

struct DeckView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase

  var body: some View {
    NavigationView {
      // Use ScrollView + ForEach because List has some default tap handler behavior that results
      // in buggy behavior when there's more than one tap action / button in the row.
      ScrollView {
        Divider()
        ForEach(sortedDecks) { deckModel in
          VStack {
            DeckRow(deckModel: deckModel).padding()
            Divider()
          }
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

private struct DeckRow: View {
  let deckModel: DeckModel

  @EnvironmentObject var collectionDatabase: CollectionDatabase
  @State private var studyViewNavigation = false
  @State private var browseNavigation = false

  var body: some View {
    ZStack {
      NavigationLink(destination: self.studyView, isActive: self.$studyViewNavigation, label: { EmptyView() })
      NavigationLink(
        destination: NotesView(
          notesResults: ObservableDeck(
            database: collectionDatabase,
            deckID: deckModel.id
          ).fetch()
        ),
        isActive: self.$browseNavigation,
        label: { EmptyView() }
      )
      HStack {
        Text(deckModel.name).lineLimit(1)
        Spacer()
        Image(systemName: "info.circle").foregroundColor(.accentColor).onTapGesture(perform: { self.browseNavigation = true })
        Image(systemName: "chevron.right").foregroundColor(.secondary)
      }
      .contentShape(Rectangle()) // You need this so the onTapGesture will work on the entire row, including padding
      .onTapGesture(perform: { self.studyViewNavigation = true })
    }
  }

  private var studyView: some View {
    StudyView(studySession: StudySession(collectionDatabase: self.collectionDatabase, decks: [deckModel.id]))
  }
}
