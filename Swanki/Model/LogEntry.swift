// Copyright © 2019-present Brian Dewey.

import Foundation
import SpacedRepetitionScheduler
import SwiftData

@Model
public final class LogEntry {
  public init(card: Card? = nil, timestamp: Date, answer: CardAnswer, oldReps: Int, studyTime: TimeInterval) {
    self.card = card
    self.timestamp = timestamp
    self.answer = answer
    self.oldReps = oldReps
    self.studyTime = studyTime
  }

  public var card: Card?
  public var timestamp: Date
  public var answer: CardAnswer
  public var oldReps: Int
  public var studyTime: TimeInterval

  public static func newCardsLearned(on date: Date) -> Predicate<LogEntry> {
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date)!

    // NOTE: You can't refer to `dateRange.lowerBound` or `dateRange.upperBound` directly in the predicate,
    // which is why we create local variables for them.
    let lowerBound = Calendar.current.startOfDay(for: date)
    let upperBound = Calendar.current.startOfDay(for: tomorrow)

    return #Predicate { entry in
      entry.timestamp >= lowerBound && entry.timestamp < upperBound && entry.oldReps == 0
    }
  }
}
