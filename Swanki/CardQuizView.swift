// Copyright © 2019-present Brian Dewey.

import Foundation
import SpacedRepetitionScheduler
import SwiftData
import SwiftUI

struct CardQuizView: View {
  var card: Card

  @State private var isShowingBack = false

  var body: some View {
    VStack {
      NewCardView(card: card, showFront: true)
      if isShowingBack {
        Divider()
        NewCardView(card: card, showFront: false)
        CardAnswerButtonRow(answers: possibleAnswers) { answer, item in
          logger.info("Selected answer \(answer.localizedName)")
          card.applySchedulingItem(item)
        }
      }
    }
    .onTapGesture {
      withAnimation {
        isShowingBack = true
      }
    }
  }

  private var possibleAnswers: [(key: CardAnswer, value: SpacedRepetitionScheduler.Item)] {
    SpacedRepetitionScheduler.builtin.scheduleItem(.init(card))
  }

  private var front: String {
    card.note?.field(at: 0) ?? ""
  }

  private var back: String {
    card.note?.field(at: 1) ?? ""
  }
}

public enum CardType: String, Codable {
  case frontThenBack
  case backThenFront
}

struct NewCardView: View {
  var card: Card
  var showFront: Bool

  var body: some View {
    switch card.type {
    case .frontThenBack:
      FrontThenBackCard(card: card, showFront: showFront)
    case .backThenFront:
      BackThenFrontCard(card: card, showFront: showFront)
    }
  }
}

struct FrontThenBackCard: View {
  var card: Card
  var showFront: Bool

  var body: some View {
    if showFront {
      Text(card.note?.field(at: 0) ?? "")
    } else {
      Text(card.note?.field(at: 1) ?? "")
    }
  }
}

struct BackThenFrontCard: View {
  var card: Card
  var showFront: Bool

  var body: some View {
    if showFront {
      Text(card.note?.field(at: 1) ?? "")
    } else {
      Text(card.note?.field(at: 0) ?? "")
    }
  }
}

private struct SelectCardView: View {
  @Query var cards: [Card]

  var body: some View {
    if cards.count > 0 {
      CardQuizView(card: cards[0])
    }
  }
}

#Preview {
  SelectCardView()
    .modelContainer(.previews)
}
