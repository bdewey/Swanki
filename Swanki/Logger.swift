// Copyright © 2019-present Brian Dewey.

import Foundation
import Logging

let logger: Logger = {
  var logger = Logger(label: "org.brians-brain.Swanki")
  logger.logLevel = .debug
  return logger
}()
