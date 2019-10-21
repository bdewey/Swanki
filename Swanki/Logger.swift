// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation
import Logging

let logger: Logger = {
  var logger = Logger(label: "org.brians-brain.Swanki")
  logger.logLevel = .debug
  return logger
}()
