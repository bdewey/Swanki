// Copyright © 2019-present Brian Dewey.

import Foundation

/// Conversions to/from some of the Anki date database formats.
public extension Date {
  init(secondsRelativeFormat seconds: Int) {
    self.init(timeIntervalSinceReferenceDate: TimeInterval(seconds))
  }

  /// "seconds relative format" -- used for cards in the "learning" category where you want sub-day granularity.
  var secondsRelativeFormat: Int {
    Int(floor(timeIntervalSinceReferenceDate))
  }

  init(dayRelativeFormat days: Int) {
    self.init(timeIntervalSinceReferenceDate: TimeInterval(days) * TimeInterval.day)
  }

  /// "day relative format" -- used for cards in the "review" category where you only need day granularity.
  var dayRelativeFormat: Int {
    Int(floor(timeIntervalSinceReferenceDate / .day))
  }
}

private extension TimeInterval {
  static let minute: TimeInterval = 60
  static let day: TimeInterval = 60 * 60 * 24
}

