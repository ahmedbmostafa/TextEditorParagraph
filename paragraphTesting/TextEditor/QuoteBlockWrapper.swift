//
//  QuoteBlockWrapper.swift
//  Quillki
//
//  Created by Nixope on 22/09/2024.
//

import SwiftUI

struct QuoteBlockWrapper: UIViewRepresentable {
    
    @EnvironmentObject var textEditorViewModel: TextEditorViewModel
    @Binding var isFirstResponder: Bool
    @Binding var textValue: NSAttributedString
    @Binding var textFont: UIFont
    @Binding var isTitleSet: Bool
    @Binding var contentBlock: TextEditorModel
    let onDeleteBackward: NilBooleanAction
    let scrollViewProxy: ScrollViewProxy
    let onReturnTapped: NilBooleanAction
    var highlightedText: String?
    var startOffset: Int?
    var endOffset: Int?
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: QuoteBlockWrapper
        private var textUpdateWorkItem: DispatchWorkItem?
        var isUserTyping = false
        var isPasteOperation = false
        
        init(parent: QuoteBlockWrapper) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            isUserTyping = true
            parent.textValue = textView.attributedText
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.isUserTyping = false
            }
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            isUserTyping = true
            isPasteOperation = text.count > 10
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isPasteOperation = false
            }
            return true
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !isUserTyping else { return }
            let selectedRange = textView.selectedRange
            let selectedLength = selectedRange.length
            getSelectedTextRange(textView: textView)
            
            DispatchQueue.main.async {
                if let text = textView.text, let range = Range(selectedRange, in: text) {
                    self.parent.highlightedText = String(text[range])
                    if self.parent.highlightedText == "" {
                        self.parent.textEditorViewModel.highlightedText = ""
                        self.parent.textEditorViewModel.selectedBodySectionUUID = nil
                        self.parent.textEditorViewModel.selectedTextFrom = -1
                        self.parent.textEditorViewModel.selectedTextTo = -1
                        self.parent.textEditorViewModel.markedType = ""
                    } else {
                        if selectedLength == 0 {
                            self.parent.highlightedText = nil
                            self.parent.textEditorViewModel.selectedBodySectionUUID = nil
                            self.parent.textEditorViewModel.highlightedText = nil
                            self.parent.textEditorViewModel.selectedTextFrom = -1
                            self.parent.textEditorViewModel.selectedTextTo = -1
                            self.parent.textEditorViewModel.markedType = ""
                        } else {
                            self.parent.textEditorViewModel.markedType = "\(self.parent.contentBlock.getComponentType())"
                            self.parent.textEditorViewModel.selectedBodySectionUUID = self.parent.contentBlock.id
                            self.parent.textEditorViewModel.highlightedText = self.parent.highlightedText
                        }
                    }
                } else {
                    self.parent.highlightedText = nil
                }
            }
        }
        
        func getSelectedTextRange(textView: UITextView) {
            if let selectedRange = textView.selectedTextRange {
                let startOffset = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
                let endOffset = textView.offset(from: textView.beginningOfDocument, to: selectedRange.end)
                if startOffset != endOffset {
                    DispatchQueue.main.async {
                        self.parent.textEditorViewModel.selectedTextFrom = startOffset
                        self.parent.textEditorViewModel.selectedTextTo = endOffset
                        self.parent.startOffset = startOffset
                        self.parent.endOffset = endOffset
                    }
                }
            }
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.textEditorViewModel.isInOrderedList = false
                self.parent.textEditorViewModel.currentListNumber = 0
                guard let index = self.parent.textEditorViewModel.contentBlocks.firstIndex(where: { $0.id == self.parent.contentBlock.id }) else { return }
                self.parent.textEditorViewModel.cursorIndex = index
                let block = self.parent.textEditorViewModel.contentBlocks[index]
                if block.isFirstResponder && !textView.isFirstResponder {
                    self.parent.textEditorViewModel.contentBlocks[index].isFirstResponder = false
                    DispatchQueue.main.async {
                        textView.resignFirstResponder()
                    }
                } else if !block.isFirstResponder && textView.isFirstResponder {
                    self.parent.textEditorViewModel.contentBlocks[index].isFirstResponder = true
                    for i in self.parent.textEditorViewModel.contentBlocks.indices {
                        if i != index {
                            self.parent.textEditorViewModel.contentBlocks[i].isFirstResponder = false
                        }
                    }
                    DispatchQueue.main.async {
                        textView.becomeFirstResponder()
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> CustomizedUITextView {
        let textView = CustomizedUITextView()
        textView.textAlignment = getAppLang() == "ar" ? .right : .left
        textView.delegate = context.coordinator
        textView.font = textFont
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.autocorrectionType = .no
        textView.linkTextAttributes = contentBlock.linkAttributes
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainer.widthTracksTextView = true
        textView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        if isFirstResponder {
            DispatchQueue.main.async {
                textView.becomeFirstResponder()
            }
        }
        return textView
    }
    
    func updateUIView(_ uiView: CustomizedUITextView, context: Context) {
        guard let index = textEditorViewModel.contentBlocks.firstIndex(where: { $0.id == contentBlock.id }) else { return }
        let block = textEditorViewModel.contentBlocks[index]
        
        // Store current state
        let currentSelectedRange = uiView.selectedRange
        let wasFirstResponder = uiView.isFirstResponder
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        let extractedText = block.extractAttributedString(content: block.content).string
        let language = detectLanguage(text: extractedText)
        (language == "ar" || language == "ur") ? (paragraphStyle.alignment = .right) : (paragraphStyle.alignment = .left)

        // Quote specific padding
        let padding: UIEdgeInsets
        padding = UIEdgeInsets(top: 4, left: (getAppLang() == "ar" || getAppLang() == "ur") ? 0 : 16, bottom: 4, right: (getAppLang() == "ar" || getAppLang() == "ur") ? 16 : 0)
        uiView.textContainerInset = padding
        
        let attributedText = NSMutableAttributedString(attributedString: block.extractAttributedString(content: block.content))
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        
        // CRITICAL: Only update text if it's actually different AND not during user interaction
        if !context.coordinator.isUserTyping &&
           !context.coordinator.isPasteOperation &&
           uiView.attributedText != attributedText {
            
            let currentText = uiView.attributedText?.string ?? ""
            let newText = attributedText.string
            
            if currentText != newText {
                uiView.attributedText = attributedText
                
                // Restore cursor position
                let newLength = uiView.attributedText.length
                if currentSelectedRange.location <= newLength &&
                   currentSelectedRange.location + currentSelectedRange.length <= newLength {
                    let safePosition = min(newLength, uiView.attributedText.length)
                    uiView.selectedRange = NSRange(location: safePosition, length: 0)
                } else {
                    uiView.selectedRange = NSRange(location: newLength, length: 0)
                }
            }
        }
        
        // Handle paste operations
        if context.coordinator.isPasteOperation {
            let selectedRange = uiView.selectedRange
            uiView.attributedText = attributedText
            let newLength = uiView.attributedText.length
            if selectedRange.location <= newLength {
                uiView.selectedRange = selectedRange
            } else {
                uiView.selectedRange = NSRange(location: newLength, length: 0)
            }
        }
        
        let selectedRange = uiView.selectedRange
        let selectedLength = selectedRange.length
        
        if selectedLength > 1 {
            let selectedRange = uiView.selectedRange
            uiView.attributedText = attributedText
            let newLength = uiView.attributedText.length
            if selectedRange.location <= newLength {
                uiView.selectedRange = selectedRange
            } else {
                uiView.selectedRange = NSRange(location: newLength, length: 0)
            }
        }
        
        if block.isFirstResponder && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        } else if !block.isFirstResponder && uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.resignFirstResponder()
            }
        }
        
        uiView.onDeleteBackward = onDeleteBackward
    }
}
