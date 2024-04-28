// Copyright © 2019-present Brian Dewey.

import Foundation

extension URLSession {
  /// Gets around the warning when you try to use `URLSession.data(from:delegate:)` about passing a nonsendable delegate across concurrency boundaries.
  nonisolated func nonisolatedData(
    from url: URL
  ) async throws -> (Data, URLResponse) {
    try await data(from: url)
  }
}
