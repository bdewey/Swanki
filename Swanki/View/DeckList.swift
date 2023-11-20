// Copyright © 2019-present Brian Dewey.

import SwiftData
import SwiftUI

/// Show all of the decks in a database.
struct DeckList: View {
  @Query private var decks: [Deck]
  @Environment(\.modelContext) private var modelContext
  @State private var editingDeck: Deck?
  @State private var shouldShowNewDeck = false
  @State private var shouldShowFileImporter = false

  var body: some View {
    List {
      ForEach(decks) { deck in
        NavigationLink {
          NoteListView(deck: deck)
        } label: {
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
        }
      }
      .onDelete(perform: { indexSet in
        for index in indexSet {
          modelContext.delete(decks[index])
        }
      })
    }
    .sheet(item: $editingDeck) { deck in
      DeckEditor(deck: deck)
    }
    .sheet(isPresented: $shouldShowNewDeck) {
      DeckEditor(deck: nil)
    }
    .navigationTitle("Decks")
    .fileImporter(isPresented: $shouldShowFileImporter, allowedContentTypes: [.ankiPackage], onCompletion: { result in
      guard let url = try? result.get() else { return }
      importPackage(at: url)
    })
    .onOpenURL(perform: { url in
      logger.info("Trying to open url \(url)")
      importPackage(at: url)
    })
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          shouldShowNewDeck = true
        } label: {
          Label("Add", systemImage: "plus")
        }
      }
      ToolbarItem(placement: .secondaryAction) {
        Button {
          logger.debug("Presenting file importer. Home directory is \(URL.homeDirectory.path)")
          shouldShowFileImporter = true
        } label: {
          Label("Import", systemImage: "square.and.arrow.down.on.square")
        }
      }
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

#Preview {
  NavigationStack {
    DeckList()
  }
  .modelContainer(.previews)
}