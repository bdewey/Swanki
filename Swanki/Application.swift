// Copyright © 2019-present Brian Dewey.

import SwiftUI

@main
struct Application: App {
  let databases: Databases = {
    let databases = Databases()
    databases.lookForExistingDatabases { foundDatabases in
      if foundDatabases.isEmpty {
        databases.makeDemoDatabase()
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
