// Copyright © 2019-present Brian Dewey.

import AVFoundation
import SwiftUI

struct FrontThenBackCard: View {
  var card: Card
  var cardSide: CardSide

  var body: some View {
    ZStack {
      switch cardSide {
      case .front:
        HStack {
          Text(card.note?.front ?? "")
          Button("Speak", systemImage: "speaker.wave.2") {
            card.note?.speakSpanish()
          }
          .labelStyle(.iconOnly)
        }
      case .back:
        Text(card.note?.back ?? "")
      }
    }
    .onAppear(perform: {
      card.note?.speakSpanish()
    })
  }
}
