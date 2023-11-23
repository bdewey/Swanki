// Copyright © 2019-present Brian Dewey.

import SwiftUI

@MainActor
/// Displays a ``StudySession``.
///
/// This view will progress through the cards of the ``StudySession``, displaying cards and recording answers as long as there are cards to display.
struct StudySessionView: View {
  var studySession: StudySession

  @State private var answerCount = 0

  var body: some View {
    VStack {
      ProgressView(value: progress)
      if let card = studySession.currentCard {
        CardQuizView(card: card, didSelectAnswer: { answer, item, studyTime in
          answerCount += 1
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
    .padding()
  }

  private var progress: Double {
    let denominator = Double(answerCount + studySession.newCardCount + studySession.learningCardCount)
    if denominator > 0 {
      return Double(answerCount) / denominator
    } else {
      return 0
    }
  }
}

private struct StudySessionView_Preview: View {
  @State private var applicationNavigation = ApplicationNavigation()

  var body: some View {
    StudySessionPlucker()
      .withStudySession()
      .environment(applicationNavigation)
      .modelContainer(.previews)
  }
}

private struct StudySessionPlucker: View {
  @Environment(StudySession.self) private var studySession: StudySession?

  var body: some View {
    if let studySession {
      StudySessionView(studySession: studySession)
    }
  }
}

#Preview {
  StudySessionView_Preview()
}
