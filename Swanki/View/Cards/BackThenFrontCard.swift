// Copyright © 2019-present Brian Dewey.

import SwiftUI

struct BackThenFrontCard: View {
  var card: Card
  var cardSide: CardSide

  var body: some View {
    switch cardSide {
    case .front:
      Text(card.note?.back ?? "")
    case .back:
      Text(card.note?.front ?? "")
    }
  }
}
