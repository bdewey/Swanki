// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI

struct ContentView: View {
  var body: some View {
    NavigationView {
      VStack {
        Text("Decks go here")
      }
      .navigationBarTitle("Swanki")
      .navigationBarItems(trailing: Image(systemName: "plus.circle"))
    }.navigationViewStyle(StackNavigationViewStyle())
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
