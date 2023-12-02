// Copyright © 2019-present Brian Dewey.

import SwiftUI

struct MacOSDialogSizeModifier: ViewModifier {
  let width: CGFloat
  let height: CGFloat

  func body(content: Content) -> some View {
    content
    #if os(macOS)
    .frame(width: width, height: height)
    #endif
  }
}

extension View {
  func withMacOSDialogFrame(width: CGFloat = 600, height: CGFloat = 400) -> some View {
    modifier(MacOSDialogSizeModifier(width: width, height: height))
  }
}
