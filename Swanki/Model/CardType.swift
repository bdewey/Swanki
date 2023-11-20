// Copyright © 2019-present Brian Dewey.

import Foundation

/// Represents the known types of cards.
public enum CardType: String, Codable {
  case frontThenBack
  case backThenFront
}
