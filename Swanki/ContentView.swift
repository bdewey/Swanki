// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var collectionDatabase: CollectionDatabase

  var body: some View {
    NavigationView {
      List(collectionDatabase.notes) { note -> Text in
        Text(note.fieldsArray.first ?? "")
      }
      .navigationBarTitle("Swanki")
    }.navigationViewStyle(StackNavigationViewStyle())
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
