// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation

public extension TimeInterval {
  /// A TimeInterval that is close to, but not necessarily identical to, the receiver.
  /// - note: The value will fall within the bounds defined by `self.fuzzRange`
  func fuzzed() -> TimeInterval {
    return Double.random(in: fuzzRange)
  }

  /// To keep cards added at the same time from always being scheduled together, we apply "fuzz" to the time interval.
  /// - note: This logic is transcribed from anki schedv2.py _fuzzIvlRange
  var fuzzRange: ClosedRange<Double> {
    if self < 2 * .day {
      return self ... self
    }
    if self < 3 * .day {
      return 2 * .day ... 3 * .day
    }
    var fuzz: TimeInterval
    if self < 7 * .day {
      fuzz = self / 4
    } else if self < 30 * .day {
      fuzz = max(2 * .day, self * 0.15)
    } else {
      fuzz = max(4 * .day, self * 0.05)
    }
    fuzz = max(1, fuzz)
    return (self - fuzz) ... (self + fuzz)
  }
}
