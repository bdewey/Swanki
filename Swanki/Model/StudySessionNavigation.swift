// Copyright © 2019-present Brian Dewey.

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class StudySessionNavigation {
  var studySession = StudySession()
  var isShowingStudySession = false

  var isDisabled: Bool {
    studySession.currentCard == nil
  }
}

struct StudySessionNavigationModifier: ViewModifier {
  let applicationNavigation: ApplicationNavigation
  @Bindable var studySessionNavigation: StudySessionNavigation
  @Environment(\.modelContext) private var modelContext

  func body(content: Content) -> some View {
    content
      .sheet(isPresented: $studySessionNavigation.isShowingStudySession) {
        StudySessionView(studySession: studySessionNavigation.studySession)
      }
      .environment(studySessionNavigation)
      .onChange(of: applicationNavigation.selectedDeck, initial: true) {
        let studySession = StudySession(modelContext: modelContext, deck: applicationNavigation.selectedDeck, newCardLimit: 20)
        do {
          try studySession.loadCards(dueBefore: .now)
          studySessionNavigation.studySession = studySession
        } catch {
          logger.error("Error loading cards: \(error)")
        }
      }
  }
}

extension View {
  func withStudySession(applicationNavigation: ApplicationNavigation, studySessionNavigation: StudySessionNavigation) -> some View {
    modifier(StudySessionNavigationModifier(applicationNavigation: applicationNavigation, studySessionNavigation: studySessionNavigation))
  }
}
