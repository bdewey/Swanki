// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase
  @State private var presentStudyView = false

  var body: some View {
    NavigationView {
      List(collectionDatabase.notes) { note -> Text in
        Text(note.fieldsArray.first ?? "")
      }
      .navigationBarTitle("Swanki")
      .navigationBarItems(trailing: Button(action: { self.presentStudyView = true }, label: {
        Text("Study")
      }))
    }
    .navigationViewStyle(StackNavigationViewStyle())
    .sheet(isPresented: $presentStudyView) {
      StudyView(deckId: 0)
        .environmentObject(self.collectionDatabase)
    }
  }
}
