// Copyright © 2019 Brian's Brain. All rights reserved.

import Foundation

/// Various Anki deck configuration parameters.
public struct DeckConfig: Codable {
  public let name: String
  public let replayq: Bool
  public let lapse: LapseConfig
  public let rev: RevConfig
  public let timer: Int
  public let maxTaken: Int
  public let usn: Int
  public let new: NewConfig
  public let mod: Int
  public let id: Int
  public let autoplay: Bool
}

public struct LapseConfig: Codable {
  public let leechFails: Int
  public let minInt: Int
  public let delays: [Int]
  public let leechAction: Int
  public let mult: Double
}

public struct RevConfig: Codable {
  public let perDay: Int
  public let ivlFct: Int
  public let maxIvl: Int
  public let minSpace: Int
  public let ease4: Double
  public let fuzz: Double
}

public struct NewConfig: Codable {
  public let perDay: Int
  public let delays: [Int]
  public let separate: Bool
  public let ints: [Int]
  public let initialFactor: Int
  public let order: Int
}
