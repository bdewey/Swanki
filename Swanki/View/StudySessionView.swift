// Copyright © 2019-present Brian Dewey.

import SwiftUI

@MainActor
/// Displays a ``StudySession``.
///
/// This view will progress through the cards of the ``StudySession``, displaying cards and recording answers as long as there are cards to display.
struct StudySessionView: View {
  var studySession: StudySession

  var body: some View {
    ZStack {
      if let card = studySession.currentCard {
        CardQuizView(card: card, didSelectAnswer: { answer, item, studyTime in
          do {
            try withAnimation {
              try studySession.updateCurrentCardSchedule(answer: answer, schedulingItem: item, studyTime: studyTime)
            }
          } catch {
            logger.error("Unexpected error scheduling card \(card.id) and answer \(answer.localizedName): \(error)")
          }
        })
        #if os(macOS)
        .frame(width: 600, height: 400)
        #endif
        .id(card.id)
      } else {
        ContentUnavailableView {
          Label("Nothing to study!", systemImage: "nosign")
        } description: {
          Text("No more cards!")
        }
      }
    }
  }
}
