// Copyright © 2019 Brian's Brain. All rights reserved.

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
  let htmlString: String

  func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
    WKWebView(frame: .zero)
  }

  func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<WebView>) {
    let htmlStart = "<HTML><HEAD><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, shrink-to-fit=no\"></HEAD><BODY>"
    let htmlEnd = "</BODY></HTML>"
    let htmlContent = "\(htmlStart)\(htmlString)\(htmlEnd)"

    uiView.loadHTMLString(htmlContent, baseURL: nil)
  }
}

struct WebView_Previews: PreviewProvider {
  static var previews: some View {
    WebView(htmlString: "<b>Testing</b> this <i>thing</i>")
  }
}
