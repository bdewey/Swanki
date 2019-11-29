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
            DeckRow(studySession: StudySession(collectionDatabase: self.collectionDatabase, deckModel: deckModel)).padding()
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

  @ObservedObject var studySession: StudySession

  @State private var studyViewNavigation = false
  @State private var browseNavigation = false

  var body: some View {
    ZStack {
      NavigationLink(destination: StudyView(studySession: studySession), isActive: self.$studyViewNavigation, label: { EmptyView() })
      NavigationLink(
        destination: NotesView(
          notesResults: ObservableDeck(
            database: studySession.collectionDatabase,
            deckID: studySession.deckModel.id
          ).fetch()
        ),
        isActive: self.$browseNavigation,
        label: { EmptyView() }
      )
      HStack {
        VStack(alignment: .leading) {
          Text(studySession.deckModel.name).lineLimit(1).font(.headline)
          HStack {
            Text("Learning: \(studySession.learningCardCount)").foregroundColor(.green)
            Text("New: \(studySession.newCardCount)").foregroundColor(.blue)
          }.font(.subheadline)
        }
        Spacer()
        Image(systemName: "info.circle").foregroundColor(.accentColor).onTapGesture(perform: { self.browseNavigation = true })
        Image(systemName: "chevron.right").foregroundColor(.secondary)
      }
      .contentShape(Rectangle()) // You need this so the onTapGesture will work on the entire row, including padding
      .onTapGesture(perform: { self.studyViewNavigation = true })
    }
  }
}
