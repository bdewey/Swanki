// Copyright © 2019-present Brian Dewey.

import AVFoundation
import SwiftUI

struct BackThenFrontCard: View {
  var card: Card
  var cardSide: CardSide

  var body: some View {
    ZStack {
      switch cardSide {
      case .front:
        Text(card.note?.back ?? "")
      case .back:
        HStack {
          Text(card.note?.front ?? "")
          Button("Speak", systemImage: "speaker.wave.2") {
            card.note?.speakSpanish()
          }
          .labelStyle(.iconOnly)
        }
      }
    }
    .onChange(of: cardSide, initial: true) {
      guard cardSide == .back else {
        return
      }
      card.note?.speakSpanish()
    }
  }
}
