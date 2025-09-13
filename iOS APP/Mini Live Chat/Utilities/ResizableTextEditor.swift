//
//  ResizableTextEditor.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/28/25.
//


import SwiftUI

struct ResizableTextEditor: UIViewRepresentable {
    @Binding var text: String
    var minHeight: CGFloat = 40
    var maxHeight: CGFloat = 120 // ~5 lines
    var onHeightChange: ((CGFloat) -> Void)? = nil

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.backgroundColor = UIColor.clear
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.delegate = context.coordinator
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        DispatchQueue.main.async {
            let size = uiView.sizeThatFits(CGSize(width: uiView.frame.width, height: CGFloat.greatestFiniteMagnitude))
            let height = min(max(size.height, minHeight), maxHeight)
            onHeightChange?(height)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ResizableTextEditor
        init(_ parent: ResizableTextEditor) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            DispatchQueue.main.async {
                let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
                let height = min(max(size.height, self.parent.minHeight), self.parent.maxHeight)
                self.parent.onHeightChange?(height)
            }
        }
    }
}
