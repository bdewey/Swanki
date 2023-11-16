//
//  CardTemplate.swift
//  Swanki
//
//  Created by Brian Dewey on 11/16/23.
//  Copyright © 2023 Brian's Brain. All rights reserved.
//

import Foundation
import SpacedRepetitionScheduler
import SwiftData
import SwiftUI

struct NewCardView: View {
  var card: Card

  @State private var isShowingBack = false

  var body: some View {
    VStack {
      Text(front)
      if isShowingBack {
        Divider()
        Text(back)
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

private struct SelectCardView: View {
  @Query var cards: [Card]

  var body: some View {
    if cards.count > 0 {
      NewCardView(card: cards[0])
    }
  }
}

#Preview {
  SelectCardView()
    .modelContainer(.previews)
}
