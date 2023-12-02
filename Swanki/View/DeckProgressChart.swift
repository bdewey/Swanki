// Copyright © 2019-present Brian Dewey.

import Charts
import SwiftUI

struct DeckProgressChart: View {
  let new: Int
  let learning: Int
  let mastered: Int

  private struct DeckProgressItem {
    let categoryName: String
    let value: Int
  }

  var body: some View {
    Chart {
      ForEach(progressItems, id: \.categoryName) { item in
        BarMark(x: .value("Count", item.value))
          .foregroundStyle(by: .value("Category", item.categoryName))
      }
    }
    .frame(idealHeight: 100, maxHeight: 100)
  }

  private var progressItems: [DeckProgressItem] {
    [
      .init(categoryName: "New", value: new),
      .init(categoryName: "Learning", value: learning),
      .init(categoryName: "Mastered", value: mastered),
    ]
  }
}

#Preview {
  DeckProgressChart(new: 90, learning: 23, mastered: 3)
}
