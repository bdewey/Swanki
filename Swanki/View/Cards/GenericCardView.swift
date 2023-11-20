// Copyright © 2019-present Brian Dewey.

import SwiftUI

/// A generic view for displaying a ``Card``. Based upon ``Card/type``, it will switch to a specific view implementation.
struct GenericCardView: View {
  var card: Card
  var cardSide: CardSide

  var body: some View {
    switch card.type {
    case .frontThenBack:
      FrontThenBackCard(card: card, cardSide: cardSide)
    case .backThenFront:
      BackThenFrontCard(card: card, cardSide: cardSide)
    }
  }
}
