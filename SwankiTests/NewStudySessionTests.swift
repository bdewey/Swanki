// Copyright © 2019-present Brian Dewey.

import SpacedRepetitionScheduler
@testable import Swanki
import SwiftData
import XCTest

@MainActor
final class NewStudySessionTests: XCTestCase {
  func testBasicStudySession() throws {
    let container = ModelContainer.previews
    let studySession = NewStudySession(modelContext: container.mainContext, newCardLimit: 20)

    var currentDate = Date.now
    try studySession.loadCards(dueBefore: currentDate)
    XCTAssertEqual(studySession.newCardCount, 20)
    XCTAssertEqual(studySession.learningCardCount, 0)

    let currentCard = try XCTUnwrap(studySession.currentCard)
    let nextItems = SpacedRepetitionScheduler.builtin.scheduleItem(.init(currentCard))
    XCTAssertEqual(nextItems.count, 3)
    let goodItem = try XCTUnwrap(nextItems.first(where: { $0.key == .good }))

    currentDate.addTimeInterval(3)
    try studySession.updateCurrentCardSchedule(
      answer: goodItem.key,
      schedulingItem: goodItem.value,
      studyTime: 3,
      currentDate: currentDate
    )
    XCTAssertEqual(studySession.newCardCount, 19)
    XCTAssertEqual(studySession.learningCardCount, 0)
    XCTAssertEqual(currentCard.reps, 1)

    currentDate.addTimeInterval(goodItem.value.interval + 1)
    try studySession.loadCards(dueBefore: currentDate)
    XCTAssertEqual(studySession.newCardCount, 19)
    XCTAssertEqual(studySession.learningCardCount, 1)

    // Make sure the new card count resets when we move to a new day
    currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
    try studySession.loadCards(dueBefore: currentDate)
    XCTAssertEqual(studySession.newCardCount, 20)
    XCTAssertEqual(studySession.learningCardCount, 1)
  }
}
