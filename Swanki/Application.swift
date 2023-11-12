// Copyright © 2019-present Brian Dewey.

import SwiftUI

@MainActor
@main
struct Application: App {
  let databases: Databases = {
    let databases = Databases()
    Task {
      if await databases.lookForExistingDatabases().isEmpty {
        await databases.makeDemoDatabase()
      }
    }
    return databases
  }()

  var body: some Scene {
    WindowGroup {
      DeckView(databases: databases)
    }
  }
}
