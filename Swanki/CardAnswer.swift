// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation

/// The different feedback you can give about how you did looking at a card
public enum CardAnswer: CaseIterable {
  /// You didn't know the answer.
  case again

  /// You got the answer but it was hard -- drill this more frequently
  case hard

  /// You got the answer. Space out the next time you need to see it again.
  case good

  /// You got the answer and it was easy... really space out how often you see it.
  case easy

  var localizedName: String {
    // TODO: Actually localize the output.
    switch self {
    case .again:
      return "Again"
    case .easy:
      return "Easy"
    case .good:
      return "Good"
    case .hard:
      return "Hard"
    }
  }
}
