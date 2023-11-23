// Copyright © 2019-present Brian Dewey.

import Observation
import SwiftData
import SwiftUI

@MainActor
@main
struct Application: App {
  @State private var fileImportNavigation = FileImportNavigation()

  var body: some Scene {
    WindowGroup {
      ApplicationContentView()
        .allowFileImports(fileImportNavigation: fileImportNavigation)
        .modelContainer(for: Deck.self, isUndoEnabled: true)
        .environment(fileImportNavigation)
    }
    .commands {
      CommandGroup(replacing: .importExport) {
        Button("Import", systemImage: "square.and.arrow.down.on.square") {
          fileImportNavigation.isShowingFileImporter = true
        }
        .keyboardShortcut("i", modifiers: [.command, .shift])
      }
    }
  }
}

/// Top-level application content.
///
/// My intent here was to create a separate `ApplicationState` instance per window but I'm not sure if that's working.
struct ApplicationContentView: View {
  @State private var applicationState = ApplicationState()

  var body: some View {
    NavigationSplitView {
      DeckList()
    } detail: {
      if let selectedDeck = applicationState.selectedDeck {
        NoteList(deck: selectedDeck)
      }
    }
    .environment(applicationState)
  }
}

@Observable
/// The main "application state" -- needs a better name
final class ApplicationState {
  var selectedDeck: Deck? {
    didSet {
      selectedNote = nil
    }
  }

  var selectedNote: PersistentIdentifier?
}
