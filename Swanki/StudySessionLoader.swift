// Copyright © 2019-present Brian Dewey.

import SwiftUI

/// A view modifier installs a ``StudySession`` into the environment that matches the current deck.
struct StudySessionLoader: ViewModifier {
  @Environment(ApplicationNavigation.self) private var applicationNavigation
  @State private var studySession: StudySession?
  @Environment(\.modelContext) private var modelContext

  func body(content: Content) -> some View {
    ZStack {
      if let studySession {
        content.environment(studySession)
      } else {
        content
      }
    }
    .onChange(of: applicationNavigation.selectedDeck, initial: true) {
      studySession = StudySession(modelContext: modelContext, deck: applicationNavigation.selectedDeck, newCardLimit: 20)
      do {
        try studySession?.loadCards(dueBefore: .now)
      } catch {
        logger.error("Error loading cards: \(error)")
      }
    }
  }
}

extension View {
  func withStudySession() -> some View {
    modifier(StudySessionLoader())
  }
}
