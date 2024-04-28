// Copyright © 2019-present Brian Dewey.

import Foundation
import os

extension Logger {
  @inlinable
  static var general: Logger {
    Logger(subsystem: Bundle.main.bundleIdentifier!, category: "general")
  }
}
