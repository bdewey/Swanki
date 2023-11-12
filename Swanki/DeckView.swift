// Copyright © 2019-present Brian Dewey.

import Anki
import GRDB
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
  static let ankiPackage = UTType("org.brians-brain.anki-package")!
}

struct DeckView: View {
  @ObservedObject var databases: Databases
  @State private var showImporter = false

  var body: some View {
    NavigationView {
      // Use ScrollView + ForEach because List has some default tap handler behavior that results
      // in buggy behavior when there's more than one tap action / button in the row.
      ScrollView {
        Divider()
        ForEach(sortedDecks) { databaseAndDeck in
          VStack {
            DeckRow(studySession: StudySession(collectionDatabase: databaseAndDeck.database, deckModel: databaseAndDeck.deck)).padding()
            Divider()
          }
        }
      }
      .navigationBarTitle("Decks")
      .navigationBarItems(trailing: Button(action: { showImporter = true }, label: { Text("Import") }))
      .fileImporter(isPresented: $showImporter, allowedContentTypes: [.ankiPackage], onCompletion: { result in
        switch result {
        case .success(let url):
          Task {
            await databases.importPackage(at: url)
          }
        case .failure(let failure):
          logger.error("Failure on import: \(failure)")
        }
      })
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }

  private var sortedDecks: [DatabaseAndDeck] {
    let decks = databases.contents.map { database in
      database.deckModels
        .filter { $0.key != 1 } // exclude "Default" decks
        .map {
          DatabaseAndDeck(database: database, deck: $0.value)
        }
    }.joined()
    return Array(decks.sorted(by: { $0.deck.name < $1.deck.name }))
  }
}

private struct DatabaseAndDeck: Identifiable {
  var id: Int { deck.id }
  let database: CollectionDatabase
  let deck: DeckModel
}

private struct DeckRow: View {
  @ObservedObject var studySession: StudySession

  @State private var studyViewNavigation = false
  @State private var browseNavigation = false

  var body: some View {
    ZStack {
      NavigationLink(destination: StudyView(studySession: studySession), isActive: $studyViewNavigation, label: { EmptyView() })
      NavigationLink(
        destination: NotesView(
          notesResults: ObservableDeck(
            database: studySession.collectionDatabase,
            deckID: studySession.deckModel.id
          ).fetch()
        ).environmentObject(studySession.collectionDatabase),
        isActive: $browseNavigation,
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
        Image(systemName: "info.circle").foregroundColor(.accentColor).onTapGesture(perform: { browseNavigation = true })
        Image(systemName: "chevron.right").foregroundColor(.secondary)
      }
      .contentShape(Rectangle()) // You need this so the onTapGesture will work on the entire row, including padding
      .onTapGesture(perform: { studyViewNavigation = true })
    }
  }
}

struct DeckView_Previews: PreviewProvider {
  static var previews: some View {
    DeckView(databases: Databases([CollectionDatabase.testDatabase]))
  }
}
