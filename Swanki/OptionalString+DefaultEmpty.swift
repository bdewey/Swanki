// Copyright © 2019-present Brian Dewey.

import Foundation

extension String? {
  /// Provides key-path equivalent syntax for `self ?? ""`
  var defaultEmpty: String {
    get {
      self ?? ""
    }
    set {
      self = newValue
    }
  }
}
