// Copyright © 2019-present Brian Dewey.

import SwiftUI

struct FrontThenBackCard: View {
  var card: Card
  var cardSide: CardSide

  var body: some View {
    switch cardSide {
    case .front:
      Text(card.note?.front ?? "")
    case .back:
      Text(card.note?.back ?? "")
    }
  }
}
