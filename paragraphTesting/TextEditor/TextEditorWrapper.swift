//
//  TextEditorWrapper.swift
//  Quillki
//
//  Created by Nixope on 08/09/2024.
//

import SwiftUI


struct TextEditorWrapperV2: UIViewRepresentable {
    
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
        var parent: TextEditorWrapperV2
        private var textUpdateWorkItem: DispatchWorkItem?
        
        init(parent: TextEditorWrapperV2) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.textValue = textView.attributedText
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n", range.location == textView.text.count {
                parent.onReturnTapped?()
                return false
            }
            
            if text == "\n" {
                let cursorLocation = range.location
                let fullText = textView.text ?? ""
                let startIndex = fullText.index(fullText.startIndex, offsetBy: cursorLocation)
                let beforeText = String(fullText[..<startIndex]).removingLeadingSpaces()
                let afterText = String(fullText[startIndex...]).removingLeadingSpaces()
                
                let oldMarkups = self.parent.contentBlock.textMarkups
                // Markups that belong to beforeText
                let beforeMarkups = oldMarkups[self.parent.contentBlock.id]?.compactMap { markup -> MarkupModel? in
                    if markup.to <= beforeText.count {
                        return markup
                    }
                    return nil
                }
                
                // Markups that belong to afterText → shift indices relative to new string
                let afterMarkups = oldMarkups[self.parent.contentBlock.id]?.compactMap { markup -> MarkupModel? in
                    if markup.from >= beforeText.count {
                        return MarkupModel(
                            type: markup.type,
                            from: markup.from - beforeText.count,
                            to: markup.to - beforeText.count,
                            url: markup.url
                        )
                    }
                    return nil
                }
                
                let range = NSRange(location: 0, length: textView.attributedText.length)
                textView.textStorage.replaceCharacters(in: range, with: beforeText)
                
                let type = self.parent.contentBlock.content
                switch type {
                case .title(_):
                    DispatchQueue.main.async {
                        self.parent.textEditorViewModel.updateTitleText(
                            for: self.parent.contentBlock.id,
                            newValue: NSAttributedString(string: beforeText),
                            updateCursor: false,
                            newMarkups: beforeMarkups ?? []
                        )
                        self.parent.textEditorViewModel.insertTitleBlock(text: afterText, markups: afterMarkups ?? [])
                    }
                    
                case .subtitle(_):
                    DispatchQueue.main.async {
                        self.parent.textEditorViewModel.updateSubtitleText(
                            for: self.parent.contentBlock.id,
                            newValue: NSAttributedString(string: beforeText),
                            updateCursor: false,
                            newMarkups: beforeMarkups ?? []
                        )
                        self.parent.textEditorViewModel.insertSubtitleBlock(text: afterText, markups: afterMarkups ?? [])
                    }
                default:
                    break
                }
                return false
            }
            return true
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            let selectedRange = textView.selectedRange
            let selectedLength = selectedRange.length
            let type = self.parent.contentBlock.content
            
            switch type {
            case .title(_), .subtitle(_):
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
            default:
                break
            }
        }
        
        func getSelectedTextRange(textView: UITextView) {
            if let selectedRange = textView.selectedTextRange {
                let startOffset = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
                let endOffset = textView.offset(from: textView.beginningOfDocument, to: selectedRange.end)
                if startOffset != endOffset {
                    parent.textEditorViewModel.selectedTextFrom = startOffset
                    parent.textEditorViewModel.selectedTextTo = endOffset
                    parent.startOffset = startOffset
                    parent.endOffset = endOffset
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
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        let extractedText = block.extractAttributedString(content: block.content)
        let language = detectLanguage(text: extractedText.string)
        (language == "ar" || language == "ur") ? (paragraphStyle.alignment = .right) : (paragraphStyle.alignment = .left)
        let attributedText = NSMutableAttributedString(attributedString: extractedText)
        let validRange = NSRange(location: 0, length: attributedText.length)
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: validRange)
        
        if uiView.attributedText != attributedText {
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

struct TextEditorWrapper: UIViewRepresentable {
    
    @EnvironmentObject var textEditorViewModel: TextEditorViewModel
    @Binding var isFirstResponder: Bool
    @Binding var textValue: String
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
        var parent: TextEditorWrapper
        private var textUpdateWorkItem: DispatchWorkItem?
        
        init(parent: TextEditorWrapper) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.textValue = textView.text
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n", range.location == textView.text.count {
                parent.onReturnTapped?()
                return false
            }
            
            if text == "\n" {
                let cursorLocation = range.location
                let fullText = textView.text ?? ""
                let startIndex = fullText.index(fullText.startIndex, offsetBy: cursorLocation)
                let beforeText = String(fullText[..<startIndex]).removingLeadingSpaces()
                let afterText = String(fullText[startIndex...]).removingLeadingSpaces()
                let range = NSRange(location: 0, length: textView.attributedText.length)
                textView.textStorage.replaceCharacters(in: range, with: beforeText)
                
                let type = self.parent.contentBlock.content
                switch type {
                    
                case .mainTitle(_):
                    DispatchQueue.main.async {
                        self.parent.textEditorViewModel.updateMainTitleText(for: self.parent.contentBlock.id, newValue: beforeText)
                        self.parent.textEditorViewModel.insertParagraphBlock(text: afterText)
                    }
                default:
                    break
                }
                return false
            }
            return true
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
        textView.text = textValue
        textView.delegate = context.coordinator
        textView.font = textFont
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.autocorrectionType = .no
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
        let textValue = block.extractText(content: block.content)
        let language = detectLanguage(text: textValue)
        (language == "ar" || language == "ur") ? (uiView.textAlignment = .right) : (uiView.textAlignment = .left)
        
        if uiView.font != block.textFont {
            uiView.font = block.textFont
        }
        
        if uiView.attributedText.string != textValue {
            let selectedRange = uiView.selectedRange
            uiView.text = textValue
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
        
        if block.isFirstResponder {
            DispatchQueue.main.async {
                textEditorViewModel.currentBlockID = block.id
                textEditorViewModel.currentBlockValue = block.extractText(content: block.content)
            }
        }
        
        uiView.onDeleteBackward = onDeleteBackward
    }
}

class CustomizedUITextView: UITextView {
    var onDeleteBackward: NilBooleanAction
    var isDeletedComponent = false
    
    override init(frame: CGRect, textContainer: NSTextContainer? = nil) {
        onDeleteBackward = nil
        super.init(frame: frame, textContainer: textContainer)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func deleteBackward() {
        if self.text.isEmpty {
            onDeleteBackward?()
            isDeletedComponent = true
        }
        super.deleteBackward()
    }
    
    override var bounds: CGRect {
        didSet {
            self.setNeedsDisplay()
            self.layoutManager.invalidateLayout(forCharacterRange: NSRange(location: 0, length: self.text.utf16.count), actualCharacterRange: nil)
        }
    }
}

typealias NilBooleanAction = (() -> Void)?
