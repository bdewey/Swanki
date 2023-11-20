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
        CardQuizView(card: card) { answer, item, studyTime in
          do {
            try studySession.updateCurrentCardSchedule(answer: answer, schedulingItem: item, studyTime: studyTime, currentDate: .now)
          } catch {
            logger.error("Unexpected error scheduling card \(card.id) and answer \(answer.localizedName): \(error)")
          }
        }
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
