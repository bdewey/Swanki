// Copyright © 2019-present Brian Dewey.

import SwiftData
import SwiftUI

/// Show all of the decks in a database.
struct DeckList: View {
  @Query private var decks: [Deck]
  @Environment(\.modelContext) private var modelContext
  @State private var editingDeck: Deck?
  @State private var shouldShowNewDeck = false
  @Environment(ApplicationNavigation.self) private var applicationNavigation
  @Environment(FileImportNavigation.self) private var fileImporterNavigation
  @Environment(StudySession.self) private var studySession: StudySession?

  var body: some View {
    @Bindable var applicationNavigation = applicationNavigation
    @Bindable var fileImporterNavigation = fileImporterNavigation
    VStack {
      List(selection: $applicationNavigation.selectedDeck) {
        ForEach(decks) { deck in
          HStack {
            Text(deck.name)
            Spacer()
            Button {
              editingDeck = deck
            } label: {
              Image(systemName: "info.circle")
                // Needs an explicit foregroundColor because of the PlainButtonStyle
                .foregroundColor(.accentColor)
            }
            // You need PlainButtonStyle() to keep the button from conflicting with
            // the tap handling for the navigation.
            .buttonStyle(PlainButtonStyle())
          }
          .tag(deck)
        }
        .onDelete(perform: { indexSet in
          for index in indexSet {
            modelContext.delete(decks[index])
          }
        })
      }
      .listStyle(.sidebar)
      if let studySession {
        Text("New = \(studySession.newCardCount) Learning = \(studySession.learningCardCount)")
      }
    }
    .sheet(item: $editingDeck) { deck in
      DeckEditor(deck: deck)
    }
    .sheet(isPresented: $shouldShowNewDeck) {
      DeckEditor(deck: nil)
    }
    .navigationTitle("Decks")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          shouldShowNewDeck = true
        } label: {
          Label("Add", systemImage: "plus")
        }
      }
      #if !os(macOS)
        ToolbarItem(placement: .secondaryAction) {
          Button {
            logger.debug("Presenting file importer. Home directory is \(URL.homeDirectory.path)")
            fileImporterNavigation.isShowingFileImporter = true
          } label: {
            Label("Import", systemImage: "square.and.arrow.down.on.square")
          }
        }
      #endif
    }
  }

  private func importPackage(at url: URL) {
    logger.info("Trying to import Anki package at url \(url)")
    let importer = AnkiPackageImporter(packageURL: url, modelContext: modelContext)
    do {
      try importer.importPackage()
      logger.info("Import complete")
    } catch {
      logger.error("Error importing package at \(url): \(error)")
    }
  }
}

extension ApplicationNavigation {
  static let previews = ApplicationNavigation()
}

#Preview {
  NavigationStack {
    DeckList()
  }
  .environment(ApplicationNavigation.previews)
  .modelContainer(.previews)
}
