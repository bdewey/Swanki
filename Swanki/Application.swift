// Copyright © 2019-present Brian Dewey.

import Observation
import SwiftData
import SwiftUI
import TipKit

@MainActor
@main
struct Application: App {
  @State private var fileImportNavigation = FileImportNavigation()
  @State private var studySessionNavigation = StudySessionNavigation()

  init() {
    do {
      try Tips.resetDatastore()
      try Tips.configure()
    } catch {
      logger.error("Error configuring tips: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      ApplicationContentView(studySessionNavigation: studySessionNavigation)
        .allowFileImports(fileImportNavigation: fileImportNavigation)
        .modelContainer(for: Deck.self)
    }
    .commands {
      CommandGroup(replacing: .importExport) {
        Button("Import", systemImage: "square.and.arrow.down.on.square") {
          fileImportNavigation.isShowingFileImporter = true
        }
        .keyboardShortcut("i", modifiers: [.command, .shift])
      }
      CommandMenu("Study") {
        Button("Study", systemImage: "rectangle.on.rectangle.angled") {
          studySessionNavigation.isShowingStudySession = true
        }
        .keyboardShortcut("s", modifiers: [.command, .shift])
        .disabled(studySessionNavigation.isDisabled)
      }
    }
  }
}

/// Top-level application content.
///
/// My intent here was to create a separate `ApplicationState` instance per window but I'm not sure if that's working.
struct ApplicationContentView: View {
  let studySessionNavigation: StudySessionNavigation
  @State private var applicationNavigation = ApplicationNavigation()

  var body: some View {
    NavigationSplitView {
      DeckList()
    } detail: {
      ZStack {
        if let selectedDeck = applicationNavigation.selectedDeck {
          NoteList(deck: selectedDeck)
        }
      }
      .toolbar {
        ToolbarItem(placement: .secondaryAction) {
          Button {
            studySessionNavigation.isShowingStudySession = true
          } label: {
            Label("Study", systemImage: "rectangle.on.rectangle.angled")
          }
          .disabled(studySessionNavigation.isDisabled)
          .help("Study")
        }
      }
    }
    .withStudySession(applicationNavigation: applicationNavigation, studySessionNavigation: studySessionNavigation)
    .environment(applicationNavigation)
  }
}
