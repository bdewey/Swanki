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
  @Environment(\.modelContext) private var modelContext

  @State private var isShowingSessionStart = true
  @State private var initialXP = 0

  var body: some View {
    NavigationStack {
      VStack {
        ProgressView(value: progress) {
          Label("+ \(currentXP - initialXP) XP", systemImage: "rectangle.on.rectangle.angled")
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
            .keyboardShortcut(" ", modifiers: [])
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
          SessionEndView(gainedXP: currentXP - initialXP)
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
      .task {
        initialXP = currentXP
      }
      #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
    }
  }

  private var currentXP: Int {
    do {
      return try modelContext.summaryStatistics().xp
    } catch {
      logger.error("Error getting summary statistics: \(error)")
      return 0
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

private struct SessionEndView: View {
  let gainedXP: Int

  var body: some View {
    ContentUnavailableView {
      Label("You gained \(gainedXP) XP!", systemImage: "flag.checkered.2.crossed")
    } description: {
      Text("Come back tomorrow to earn more XP.")
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

#Preview {
  SessionEndView(gainedXP: 20)
}
