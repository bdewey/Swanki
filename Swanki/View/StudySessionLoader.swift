// Copyright © 2019-present Brian Dewey.

import SwiftUI

/// Given a ``Deck``, loads a ``StudySession`` for that deck.
// TODO: Figure out if I can get rid of this view now that I fixed my observation bug.
struct StudySessionLoader: View {
  let deck: Deck
  @State private var studySession: StudySession?
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    ZStack {
      if let studySession {
        StudySessionView(studySession: studySession)
      } else {
        ProgressView()
      }
    }
    .onAppear {
      studySession = StudySession(modelContext: modelContext, deck: deck, newCardLimit: 20)
      do {
        try studySession?.loadCards(dueBefore: .now)
      } catch {
        logger.error("Unexpected error loading cards: \(error)")
      }
    }
  }
}
