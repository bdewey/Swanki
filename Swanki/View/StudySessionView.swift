// Copyright © 2019-present Brian Dewey.

import SwiftUI

@MainActor
/// Displays a ``StudySession``.
///
/// This view will progress through the cards of the ``StudySession``, displaying cards and recording answers as long as there are cards to display.
struct StudySessionView: View {
  var studySession: StudySession

  @State private var answerCount = 0
  @Environment(\.dismiss) private var dismiss

  @State private var isShowingSessionStart = true

  var body: some View {
    NavigationStack {
      VStack {
        ProgressView(value: progress) {
          Label(studySession.displaySummary, systemImage: "rectangle.on.rectangle.angled")
            .foregroundColor(.secondary)
        }
        if isShowingSessionStart {
          VStack {
            Spacer()
            Text("You can earn **\(studySession.estimatedGainableXP) XP** by studying today!")
            Button("Let's go!", systemImage: "arrowshape.right") {
              withAnimation {
                isShowingSessionStart = false
              }
            }
            Spacer()
          }
        } else if let card = studySession.currentCard {
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
      .withMacOSDialogFrame()
      .navigationTitle("Study")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
    }
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

@MainActor
private struct StudySessionView_Preview: View {
  @State private var applicationNavigation = ApplicationNavigation()
  @State private var studySessionNavigation = StudySessionNavigation()

  var body: some View {
    StudySessionView(studySession: studySessionNavigation.studySession)
      .withMacOSDialogFrame()
      .withStudySession(applicationNavigation: applicationNavigation, studySessionNavigation: studySessionNavigation)
      .environment(applicationNavigation)
      .modelContainer(.previews)
  }
}

#Preview {
  StudySessionView_Preview()
}
