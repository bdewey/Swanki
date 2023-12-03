// Copyright © 2019-present Brian Dewey.

import SpacedRepetitionScheduler
@testable import Swanki
import SwiftData
import XCTest

@MainActor
final class NewStudySessionTests: XCTestCase {
  func testBasicStudySession() throws {
    let container = ModelContainer.previews
    let studySession = StudySession(modelContext: container.mainContext, newCardLimit: 20)

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

    // Make sure the deck-filtered version of the study session has the right counts
    let filteredStudySession = StudySession(modelContext: container.mainContext, deck: currentCard.deck, newCardLimit: 20)
    try filteredStudySession.loadCards(dueBefore: currentDate)
    XCTAssertEqual(filteredStudySession.newCardCount, 19)
    XCTAssertEqual(filteredStudySession.learningCardCount, 1)

    // A study session based on the OTHER deck should still be able to study 20 cards
    let decks = try container.mainContext.fetch(FetchDescriptor<Deck>())
    let otherDeck = try XCTUnwrap(decks.filter { $0.name != currentCard.deck?.name }.first)
    let otherStudySession = StudySession(modelContext: container.mainContext, deck: otherDeck, newCardLimit: 20)
    try otherStudySession.loadCards(dueBefore: currentDate)
    XCTAssertEqual(otherStudySession.newCardCount, 20)
    XCTAssertEqual(otherStudySession.learningCardCount, 0)

    // Make sure the new card count resets when we move to a new day
    currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
    try studySession.loadCards(dueBefore: currentDate)
    XCTAssertEqual(studySession.newCardCount, 20)
    XCTAssertEqual(studySession.learningCardCount, 1)
  }

  func testStudySessionFiltersByDeck() throws {
    let container = try ModelContainer(for: Deck.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let deck = container.createSampleDeck(named: "Sample data", noteCount: 2)
    let decoy = container.createSampleDeck(named: "Decoy", noteCount: 2)

    let studySession = StudySession(modelContext: container.mainContext, deck: deck, newCardLimit: 20)
    var currentDate = Date.now
    try studySession.loadCards(dueBefore: currentDate)
    XCTAssertEqual(studySession.newCardCount, 4)
    XCTAssertEqual(studySession.learningCardCount, 0)
    let currentCard = try XCTUnwrap(studySession.currentCard)
    let nextItems = SpacedRepetitionScheduler.builtin.scheduleItem(.init(currentCard))
    let goodItem = try XCTUnwrap(nextItems.first(where: { $0.key == .good }))
    try studySession.updateCurrentCardSchedule(
      answer: goodItem.key,
      schedulingItem: goodItem.value,
      studyTime: 3,
      currentDate: currentDate,
      reloadCardsDueBefore: currentDate
    )
    XCTAssertEqual(studySession.newCardCount, 3)
    XCTAssertEqual(studySession.learningCardCount, 0)
    let decoyStudySession = StudySession(modelContext: container.mainContext, deck: decoy, newCardLimit: 20)
    try decoyStudySession.loadCards(dueBefore: currentDate)
    XCTAssertEqual(decoyStudySession.newCardCount, 4)
    XCTAssertEqual(decoyStudySession.learningCardCount, 0)

    currentDate.addTimeInterval(goodItem.value.interval + 1)
    try studySession.loadCards(dueBefore: currentDate)
    XCTAssertEqual(studySession.newCardCount, 3)
    XCTAssertEqual(studySession.learningCardCount, 1)

    try decoyStudySession.loadCards(dueBefore: currentDate)
    XCTAssertEqual(decoyStudySession.newCardCount, 4)
    XCTAssertEqual(decoyStudySession.learningCardCount, 0)

    let unfilteredStudySession = StudySession(modelContext: container.mainContext, newCardLimit: 20)
    try unfilteredStudySession.loadCards(dueBefore: currentDate)
    XCTAssertEqual(unfilteredStudySession.newCardCount, 7)
    XCTAssertEqual(unfilteredStudySession.learningCardCount, 1)
  }

  func testEstimatedXPAccuracy() throws {
    let container = try ModelContainer(for: Deck.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let deck = container.createSampleDeck(named: "Sample data", noteCount: 20)
    let studySession = StudySession(modelContext: container.mainContext, newCardLimit: 20)

    XCTAssertEqual(try container.mainContext.summaryStatistics().xp, 0)
    var currentDate = Date.now
    try studySession.loadCards(dueBefore: currentDate)
    XCTAssertEqual(studySession.newCardCount, 20)
    XCTAssertEqual(studySession.learningCardCount, 0)
    let estimatedGainableXP = studySession.estimatedGainableXP
    XCTAssertEqual(estimatedGainableXP, 40)

    while let card = studySession.currentCard {
      let items = SpacedRepetitionScheduler.builtin.scheduleItem(.init(card))
      let goodItem = try XCTUnwrap(items.first(where: { $0.key == .good }))
      try studySession.updateCurrentCardSchedule(answer: goodItem.key, schedulingItem: goodItem.value, studyTime: 3)
    }

    XCTAssertEqual(try container.mainContext.summaryStatistics().xp, estimatedGainableXP)
  }
}
