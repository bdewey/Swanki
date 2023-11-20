// Copyright © 2019-present Brian Dewey.

import SwiftUI

@MainActor
@main
struct Application: App {
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        DecksView()
      }
      .modelContainer(for: Deck.self)
    }
  }
}
