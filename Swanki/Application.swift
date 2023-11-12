//
//  Application.swift
//  Swanki
//
//  Created by Brian Dewey on 11/11/23.
//  Copyright © 2023 Brian's Brain. All rights reserved.
//

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
