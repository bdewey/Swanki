// Copyright © 2019-present Brian Dewey.

import SwiftUI

@MainActor
/// Sets up an environment for previews.
struct PreviewEnvironmentModifier: ViewModifier {
  @State private var applicationNavigation = ApplicationNavigation()
  @State private var fileImportNavigation = FileImportNavigation()
  @State private var studySessionnNavigation = StudySessionNavigation()

  func body(content: Content) -> some View {
    content
      .environment(applicationNavigation)
      .environment(fileImportNavigation)
      .environment(studySessionnNavigation)
      .modelContainer(.previews)
  }
}

extension View {
  @MainActor
  func withPreviewEnvironment() -> some View {
    modifier(PreviewEnvironmentModifier())
  }
}
