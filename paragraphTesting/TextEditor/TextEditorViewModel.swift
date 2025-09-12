//
//  TextEditorViewModel.swift
//  paragraphTesting
//
//  Created by Ahmed beddah on 12/09/2025.
//

import SwiftUI
import Combine

class TextEditorViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var contentBlocks: [TextEditorModel] = []
    @Published var oldContentBlocks: [TextEditorModel] = []
//    @Published var articles: [ArticleModel] = []
    @Published var isFirstResponder = false
    @Published var cursorIndex = -1
    @Published var scrollToBlock = UUID()
    @Published var isTitleSet = false
    @Published var isCodeBlock = false
    @Published var showImagePicker = false
    @Published var section: [String: Any] = [:]
    @Published var orderListDict: [UUID: (count: Int, value: String)] = [:]
    @Published var bulletedListDict: [UUID: (count: Int, value: String)] = [:]
//    @Published var videoMetadata: VideoMetadata!
    @Published var isVideoMetadata = false
    @Published var isUserDraftArticle = false
    @Published var isNewTextEditor = false
    @Published var userImage: URL?
    @Published var articleTitle = ""
    @Published var draftArticleUUID = ""
    @Published var codeBlockLanguage = ""
    @Published var articleSlug = ""
    @Published var isTopicsAdd = false
    @Published var isBodySectionUpdated = false
    @Published var isBulkUpdate = false
    @Published var isPublished = false
    @Published var showMoreMenu = false
    @Published var trackedContentID: UUID?
    @Published var showParagraphDirection = false
    @Published var showPreview = false
    @Published var joinedUserTopics: [String] = []
    @Published var topicSearchValue = ""
    @Published var addedTopicsID: [String] = []
    @Published var highlightedText: String?
    @Published var selectedBodySectionUUID: UUID?
    @Published var selectedTextFrom = -1
    @Published var selectedTextTo = -1
    @Published var scrollViewProxy: ScrollViewProxy?
    @Published var focusedField: UUID?
    @Published var showMarkupsMenu = false
    @Published var showVideoAlert = false
    @Published var textMarkups: [MarkupModel] = []
    @Published var markedType = ""
    @Published var trackedMarkupType = ""
    @Published var isValidHyperlink = false
    @Published var hyperlink = ""
    @Published var videolink = ""
    @Published var currentListNumber = 0
    @Published var isInOrderedList = false
    @Published var currentBlockValue = ""
    @Published var currentBlockID = UUID()
    @Published var unsplashImageDetails: TextEditorImageModel!
    @Published var selectedUnsplashImage: UIImage?
    @Published var date = Date()
    @Published var showCalender = false
    @Published var showTimePicker = false
    @Published var isSchedulePublishing = false
    @Published var spinnerWidth = 0.0
    @Published var showQuoteMenu = false
    @Published var showListMenu = false
//    @Published var quoteAsset = getAppLang() == "ar" ? "highlighted_quote_texteditor_ar" : "highlighted_quote_texteditor"
//    @Published var listAsset = getAppLang() == "ar" ? "bulletedlist_texteditor_ar" : "bulletedlist_texteditor"
    @Published var selectedQuoteAsset = -1
    @Published var selectedListAsset = -1
    @Published var listAssetStackPosition: CGPoint = .zero
    @Published var quoteAssetStackPosition: CGPoint = .zero
    @Published var isPublishedTapped = false
    @Published var showSuccessView = false
    @Published var successMessageValue = ""
    @Published var isCustomLoading = false
    @Published var isLoading = false
    @Published var isError = false
    @Published var errorMessageValue = ""
//    private let homeService: HomeServiceable
//    private let articleService: ArticlesServiceable
//    private let userService: UserServiceable
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        
    }
}

// MARK: - ParagraphBlock

extension TextEditorViewModel {
    func insertParagraphBlock(text: String = "", isFirstResponder: Bool = true, markups: [MarkupModel] = []) {
        let attributedString = createAttributedString(text: text)
        let newTextBlock = createNewTextBlock(content: .paragraph(attributedString), isFirstResponder: isFirstResponder)
        applyMarkupWithInsertion(markups: markups, blockId: newTextBlock.id, attributedString: attributedString)
        
        isTitleSet = true
        updateFirstResponder(newBlockID: newTextBlock.id)
    }
    
    func updateParagraphText(for blockId: UUID, newValue: NSAttributedString, updateCursor: Bool = true, newMarkups: [MarkupModel] = []) {
        updateTextBlockContent(blockId, newValue, contentType: .paragraph(newValue), marginHeight: 10, updateCursor: updateCursor, newMarkups: newMarkups)
    }
}



extension TextEditorViewModel {
    private func createAttributedString(text: String = "", font: UIFont? = nil, fontSize: CGFloat = 20, color: UIColor = UIColor.black) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: attributedString.length)
        if font != nil {
            attributedString.addAttribute(.font, value: font, range: range)
        } else {
            let font = UIFont.systemFont(ofSize: fontSize, weight: .regular)//UIFont.quillkiRegular(fontSize, text: text)
            attributedString.addAttribute(.font, value: font, range: range)
        }
        attributedString.addAttribute(.foregroundColor, value: color, range: range)
        return attributedString
    }
    
    private func createNewTextBlock(content: TextEditorContent, isFirstResponder: Bool) -> TextEditorModel {
        let newTextBlock = TextEditorModel(
            id: UUID(),
            textHeight: 38,
            textFont: UIFont.systemFont(ofSize: 20, weight: .regular),
            content: content,
            contentOrder: cursorIndex + 1,
            isFirstResponder: isFirstResponder,
            isTitleSet: true
        )
        let emptyBlock = TextEditorModel(
            id: UUID(),
            textHeight: 300,
            textFont: UIFont.systemFont(ofSize: 10, weight: .regular),
            content: .empty(""),
            contentOrder: 0,
            isFirstResponder: false,
            isTitleSet: true
        )
        
        if case .empty(_) = contentBlocks.last?.content {
            contentBlocks.removeLast()
        }
        if contentBlocks.count < cursorIndex + 1 {
            contentBlocks.append(newTextBlock)
        } else {
            contentBlocks.insert(newTextBlock, at: cursorIndex + 1)
        }
        if case .mainTitle(_) = contentBlocks.first?.content {
            contentBlocks = contentBlocks.enumerated().map { index, block in
                var updatedBlock = block
                updatedBlock.contentOrder = index
                return updatedBlock
            }
        }
        contentBlocks.append(emptyBlock)
        return newTextBlock
    }
    
    private func updateTextBlockContent(_ blockId: UUID, _ newValue: NSAttributedString, font: UIFont? = nil, contentType: TextEditorContent, marginHeight: Int, isCustomRange: Bool = false, updateCursor: Bool = true, newMarkups: [MarkupModel] = []) {
        if let index = contentBlocks.firstIndex(where: { $0.id == blockId }) {

            if contentBlocks[index].isFirstResponder && index == cursorIndex {
                DispatchQueue.main.async {
                    self.currentBlockID = blockId
                    self.currentBlockValue = newValue.string
                }
            }
            
            DispatchQueue.main.async {
                if !newMarkups.isEmpty {
                    self.textMarkups = newMarkups
                } else {
                    self.textMarkups = self.contentBlocks[index].textMarkups[blockId] ?? []
                }
//                self.textMarkups = self.contentBlocks[index].textMarkups[blockId] ?? []
                let attributedString = NSMutableAttributedString(attributedString: newValue)
                let totalLength = attributedString.string.utf16.count
                let range = NSRange(location: 0, length: totalLength)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byCharWrapping
                if font != nil {
                    attributedString.addAttribute(.font, value: font, range: range)
                } else {
                    let font = UIFont.systemFont(ofSize: 20, weight: .regular)
                    attributedString.addAttribute(.font, value: font, range: range)
                }
                
                attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
                attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: range)
                self.updateMarkups(for: blockId, attributedString: attributedString, index: index, totalLength: totalLength, newMarkups: newMarkups)
                switch contentType {
                case .title:
                    self.contentBlocks[index].content = .title(attributedString)
                case .subtitle:
                    self.contentBlocks[index].content = .subtitle(attributedString)
                case .paragraph:
                    self.contentBlocks[index].content = .paragraph(attributedString)
                case .orderedList:
                    self.contentBlocks[index].content = .orderedList(attributedString)
                case .bulletedList:
                    self.contentBlocks[index].content = .bulletedList(attributedString)
                case .quote:
                    self.contentBlocks[index].content = .quote(attributedString)
                case .highlightedQuote:
                    self.contentBlocks[index].content = .highlightedQuote(attributedString)
                default:
                    break
                }
                
                self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 40, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(marginHeight))
                
                if updateCursor {
                    self.updateFirstResponder(newBlockID: blockId)
                }
            }
        }
    }
    
    func updateMarkups(for blockId: UUID, attributedString: NSMutableAttributedString, index: Int, totalLength: Int, newMarkups: [MarkupModel] = []) {
        if textMarkups.count > 0 {
            for (markupIndex, markup) in textMarkups.enumerated() {
                // Check if the new text range overlaps with any markup
                if (selectedTextFrom >= markup.from && selectedTextFrom <= markup.to) ||
                    (selectedTextTo >= markup.from && selectedTextTo <= markup.to) {
                    
                    // Remove the specific markup by its index
                    contentBlocks[index].textMarkups[blockId]?.remove(at: markupIndex)
                    // Add the new markup with updated range
                    let newMarkup = MarkupModel(
                        type: markup.type,
                        from: selectedTextFrom,
                        to: selectedTextTo,
                        url: markup.url
                    )
                    contentBlocks[index].textMarkups[blockId]?.append(newMarkup)
                    textMarkups = contentBlocks[index].textMarkups[blockId] ?? []
                } else {
                    if !newMarkups.isEmpty {
                        contentBlocks[index].textMarkups[blockId] = newMarkups
                    }
                    removeInheritedAttributes(attributedString: attributedString)
                    applyMarkup(blockId: blockId, attributedString: attributedString, componentIndex: index, markup: markup, markupIndex: markupIndex, totalLength: totalLength)
                }
            }
        }
    }
    
    func applyMarkup(blockId: UUID, attributedString: NSMutableAttributedString, componentIndex: Int, markup: MarkupModel, markupIndex: Int, totalLength: Int) {
        // check markup overlap
        let markupRange = NSRange(location: markup.from, length: markup.to - markup.from)
        guard markupRange.location >= 0, markupRange.location + markupRange.length <= totalLength else {
            // remove link markup
            if markup.type == "link" {
                let safeRange = NSRange(
                    location: max(0, min(markupRange.location, totalLength - 1)),
                    length: max(0, min(markupRange.length, totalLength - markupRange.location))
                )
                attributedString.removeAttribute(.link, range: safeRange)
                attributedString.removeAttribute(.underlineStyle, range: safeRange)
            }
            // Remove the invalid markup
            if textMarkups.count > 0 {
                contentBlocks[componentIndex].textMarkups[blockId]?.remove(at: markupIndex)
            }
            textMarkups = contentBlocks[componentIndex].textMarkups[blockId] ?? []
            return
        }
        // Apply markup based on its type
        switch markup.type {
        case "link":
            let url = URL(string: markup.url ?? "") ?? URL(string: "www.nixope.com")!
            attributedString.addAttribute(.link, value: url, range: markupRange)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: markupRange)
        case "italic":
            let font = UIFont.systemFont(ofSize: 20, weight: .regular)
            attributedString.addAttribute(.font, value: font, range: markupRange)
        case "bold":
            let font = UIFont.systemFont(ofSize: 20, weight: .bold)
            attributedString.addAttribute(.font, value: font, range: markupRange)
        case "bolditalic":
            let font = UIFont.systemFont(ofSize: 20, weight: .bold)
            attributedString.addAttribute(.font, value: font, range: markupRange)
        default:
            break
        }
    }
    
    private func removeInheritedAttributes(attributedString: NSMutableAttributedString) {
        // Remove inherited attributes (link, underline) from newly typed text
        if let typingRange = attributedString.string.range(of: attributedString.string) {
            let nsTypingRange = NSRange(typingRange, in: attributedString.string)
            attributedString.removeAttribute(.link, range: nsTypingRange)
            attributedString.removeAttribute(.underlineStyle, range: nsTypingRange)
        }
    }
    
    private func updateFirstResponder(newBlockID: UUID) {
        if let index = contentBlocks.firstIndex(where: { $0.id == newBlockID }) {
            for i in contentBlocks.indices {
                if i != index {
                    contentBlocks[i].isFirstResponder = false
                }
            }
        }
    }
    
    func applySelectedMarkup(markupType: String, markupFont: UIFont?, hyperlink: String? = nil) {
        var markupType = markupType
        guard let selectedUUID = selectedBodySectionUUID else { return }
        guard let index = contentBlocks.firstIndex(where: { $0.id == selectedUUID }) else { return }
        
        let attributedString = NSMutableAttributedString(
            attributedString: contentBlocks[index].extractAttributedString(content: contentBlocks[index].content)
        )
        
        let range = NSRange(location: selectedTextFrom, length: selectedTextTo - selectedTextFrom)
        var markupArray = contentBlocks[index].textMarkups[selectedUUID] ?? []
        let baseFont = contentBlocks[index].textFont // stored font for revert
        
        // Helper: get current bold/italic state from a font
        func fontStates(for font: UIFont) -> (bold: Bool, italic: Bool) {
            let name = font.fontName.lowercased()
            return (name.contains("bold"), name.contains("italic"))
        }
        
        // ====== Check if markup exists ======
        if let existingIndex = markupArray.firstIndex(where: { $0.from == selectedTextFrom && $0.to == selectedTextTo }) {
            let existingMarkup = markupArray[existingIndex]
            let oldRange = NSRange(location: existingMarkup.from, length: existingMarkup.to - existingMarkup.from)
            if NSEqualRanges(oldRange, range) {
                // ✅ Same range → undo
                let oldMarkupType = existingMarkup.type
                markupArray.remove(at: existingIndex)
                
                if markupType == "link" {
                    attributedString.removeAttribute(.link, range: range)
                    attributedString.removeAttribute(.underlineStyle, range: range)
                } else if let currentFont = attributedString.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont {
                    var isBold = false
                    var isItalic = false
                    
                    // Remove just the toggled style
                    if markupType == "bold" { isBold = true }
                    if markupType == "italic" { isItalic = true }
                    let finalFont = resolveFont(isOldMarkup: true, markupType: oldMarkupType, baseFont: baseFont, isBold: isBold, isItalic: isItalic, attributedString: attributedString)
                    attributedString.addAttribute(.font, value: finalFont, range: range)
                }
                
                let fontName = baseFont.fontName.lowercased()
                if fontName.contains("bolditalic") {
                    markupType = "bolditalic"
                    trackedMarkupType = "bolditalic"
                }
                
                let markup = MarkupModel(type: trackedMarkupType, from: selectedTextFrom, to: selectedTextTo, url: hyperlink)
                markupArray.append(markup)
                contentBlocks[index].textMarkups[selectedUUID] = markupArray
            } else {
                // ⚠️ Different range → treat as new markup
                applyNewMarkup(pure: true, attributedString: attributedString)
            }
        } else {
            // No existing markup → add new
            applyNewMarkup(pure: false, attributedString: attributedString)
        }
        
        // ====== Update block content ======
        switch contentBlocks[index].content {
        case .title:
            contentBlocks[index].content = .title(attributedString)
        case .subtitle:
            contentBlocks[index].content = .subtitle(attributedString)
        case .paragraph:
            contentBlocks[index].content = .paragraph(attributedString)
        case .orderedList:
            contentBlocks[index].content = .orderedList(attributedString)
        case .bulletedList:
            contentBlocks[index].content = .bulletedList(attributedString)
        case .quote:
            contentBlocks[index].content = .quote(attributedString)
        case .highlightedQuote:
            contentBlocks[index].content = .highlightedQuote(attributedString)
        default:
            break
        }
        
        // ====== Inner function ======
        func applyNewMarkup(pure: Bool, attributedString: NSMutableAttributedString) {
            var finalFont = markupFont
            
            if let currentFont = attributedString.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont , markupType != "link" {
                var (isBold, isItalic) = fontStates(for: currentFont)
                if markupType == "bold" { isBold = true }
                if markupType == "italic" { isItalic = true }
                
                finalFont = resolveFont(markupType: markupType, baseFont: baseFont, isBold: isBold, isItalic: isItalic, attributedString: attributedString)
                let fontName = finalFont!.fontName.lowercased()
                if fontName.contains("bolditalic") {
                    markupType = "bolditalic"
                }
            } else {
                // No font → start fresh from baseFont
                if markupType != "link" {
                    let isBold = (markupType == "bold")
                    let isItalic = (markupType == "italic")
                    finalFont = resolveFont(markupType: markupType, baseFont: baseFont, isBold: isBold, isItalic: isItalic, attributedString: attributedString)
                    let fontName = finalFont!.fontName.lowercased()
                    if fontName.contains("bolditalic") {
                        markupType = "bolditalic"
                    }
                }
            }
            
            if let fontToApply = finalFont , markupType != "link" {
                attributedString.addAttribute(.font, value: fontToApply, range: range)
            }
            
            if markupType == "link", let hyperlink = hyperlink, let url = URL(string: hyperlink) {
                attributedString.addAttribute(.link, value: url, range: range)
                attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                contentBlocks[index].linkAttributes = [
                    NSAttributedString.Key.foregroundColor: UIColor.black
                ]
            }
            
            let markup = MarkupModel(type: markupType, from: selectedTextFrom, to: selectedTextTo, url: hyperlink)
            markupArray.append(markup)
            contentBlocks[index].textMarkups[selectedUUID] = markupArray
        }
    }
    
    private func resolveFont(isOldMarkup: Bool = false, markupType: String = "", baseFont: UIFont, isBold: Bool, isItalic: Bool, attributedString: NSMutableAttributedString) -> UIFont {
        if isOldMarkup {
            switch markupType {
            case "italic":
                if isBold {
                    trackedMarkupType = "bolditalic"
                    return UIFont.systemFont(ofSize: baseFont.pointSize, weight: .regular)
                } else if isItalic {
                    trackedMarkupType = ""
                    return  UIFont.systemFont(ofSize: baseFont.pointSize, weight: .regular)
                }
            case "bold":
                if isBold {
                    trackedMarkupType = ""
                    return  UIFont.systemFont(ofSize: baseFont.pointSize, weight: .regular)
                } else if isItalic {
                    trackedMarkupType = "bolditalic"
                    return UIFont.systemFont(ofSize: baseFont.pointSize, weight: .regular)
                }
            case "bolditalic":
                if isBold {
                    trackedMarkupType = "italic"
                    return  UIFont.systemFont(ofSize: baseFont.pointSize, weight: .regular)
                } else if isItalic {
                    trackedMarkupType = "bold"
                    return UIFont.systemFont(ofSize: baseFont.pointSize, weight: .regular)
                }
            default:
                break
            }
        } else {
            if isBold && isItalic {
                trackedMarkupType = "bolditalic"
                return  UIFont.systemFont(ofSize: baseFont.pointSize, weight: .regular)
            } else if isBold {
                trackedMarkupType = "bold"
                return  UIFont.systemFont(ofSize: baseFont.pointSize, weight: .regular)
            } else if isItalic {
                trackedMarkupType = "italic"
                return  UIFont.systemFont(ofSize: baseFont.pointSize, weight: .regular)
            } else {
                trackedMarkupType = ""
                return  UIFont.systemFont(ofSize: baseFont.pointSize, weight: .regular)
            }
        }
        return  UIFont.systemFont(ofSize: baseFont.pointSize, weight: .regular)
    }
    
    func applyMarkupWithInsertion(markups: [MarkupModel], blockId: UUID, attributedString: NSMutableAttributedString) {
        if !markups.isEmpty {
            // 3. Apply markups (reuse existing functions)
               let blockId = blockId
               let componentIndex = contentBlocks.firstIndex { $0.id == blockId } ?? 0
               let totalLength = attributedString.length
               
               // Store markups in contentBlocks (so updateMarkups/applyMarkup works)
               contentBlocks[componentIndex].textMarkups[blockId] = markups
               textMarkups = markups

               // Actually apply the markups to attributed string
               for (markupIndex, markup) in markups.enumerated() {
                   applyMarkup(
                       blockId: blockId,
                       attributedString: attributedString,
                       componentIndex: componentIndex,
                       markup: markup,
                       markupIndex: markupIndex,
                       totalLength: totalLength
                   )
               }
        }
    }
    
    private func calculateTextHeightQuote(text: NSAttributedString, width: CGFloat, textFont: UIFont, marginHeight: CGFloat) -> CGFloat {
        let boundingSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let boundingRect = text.boundingRect(
            with: boundingSize,
            options: options,
            context: nil
        )
        let height = ceil(boundingRect.height) + marginHeight
        print("newValue==", text.string, "\n\n", height)
        
        return height
    }
}


extension TextEditorViewModel {
    func handleDeleteAction(for blockId: UUID, insertParagraph: Bool = false) {
        contentBlocks = contentBlocks.map { block in
            if block.contentOrder >= cursorIndex {
                var updatedBlock = block
                updatedBlock.contentOrder -= 1
                return updatedBlock
            }
            return block
        }
        
        if let index = contentBlocks.firstIndex(where: { $0.id == blockId }) {
            guard index > 0 else { return }
            if case .image(_) = contentBlocks[index - 1].content {
                switch contentBlocks[index].content {
                case .title(_), .subtitle(_), .paragraph(_), .codeBlock(_), .orderedList(_), .bulletedList(_), .quote(_), .highlightedQuote(_), .lineBreak(_), .divider(_), .empty(_):
                    contentBlocks.remove(at: index)
                    contentBlocks.remove(at: index - 1)
                    let newFocusIndex = index - 2
                    if newFocusIndex >= 0 {
                        contentBlocks[newFocusIndex].isFirstResponder = true
                    }
                    
                    if newFocusIndex == 0 {
                        isTitleSet = false
                    }
                    return
                    
                default:
                    break
                }
                
            } else if case .video(_) = contentBlocks[index - 1].content {
                switch contentBlocks[index].content {
                case .title(_), .subtitle(_), .paragraph(_), .codeBlock(_), .orderedList(_), .bulletedList(_), .quote(_), .highlightedQuote(_), .lineBreak(_), .divider(_), .empty(_):
                    contentBlocks.remove(at: index)
                    contentBlocks.remove(at: index - 1)
                    
                    let newFocusIndex = index - 2
                    if newFocusIndex >= 0 {
                        contentBlocks[newFocusIndex].isFirstResponder = true
                    }
                    
                    if newFocusIndex == 0 {
                        isTitleSet = false
                    }
                    return
                    
                default:
                    break
                }
                
            } else if case .divider(_) = contentBlocks[index - 1].content {
                switch contentBlocks[index].content {
                case .title(_), .subtitle(_), .paragraph(_), .codeBlock(_), .orderedList(_), .bulletedList(_), .quote(_), .highlightedQuote(_), .lineBreak(_), .divider(_), .empty(_):
                    contentBlocks.remove(at: index)
                    contentBlocks.remove(at: index - 1)
                    
                    let newFocusIndex = index - 2
                    if newFocusIndex >= 0 {
                        contentBlocks[newFocusIndex].isFirstResponder = true
                    }
                    
                    if newFocusIndex == 0 {
                        isTitleSet = false
                    }
                    return
                    
                default:
                    break
                }
                
            } else {
                switch contentBlocks[index].content {
                case .title(_), .subtitle(_), .paragraph(_), .codeBlock(_), .orderedList(_), .bulletedList(_), .quote(_), .highlightedQuote(_), .lineBreak(_), .divider(_), .video(_), .empty(_):
                    contentBlocks[index].isFirstResponder = false
                    contentBlocks.remove(at: index)
                    adjustFocusAfterDelete(index: index)
                default:
                    contentBlocks.remove(at: index)
                    adjustFocusAfterDelete(index: index)
                }
            }
        }
        
        if insertParagraph {
            cursorIndex -= 1
            insertParagraphBlock()
        }
    }
    
    func adjustFocusAfterDelete(index: Int) {
        guard index > 0 else { return }
        
        if index == 1 && index <= contentBlocks.count - 1, case .image(_) = contentBlocks[index].content {
            contentBlocks[0].isFirstResponder = true
            isTitleSet = false
            return
        }
        print("contentBlocks=", index, contentBlocks.count-1)
        if index < contentBlocks.count-1 || index == contentBlocks.count-1 {
            contentBlocks[index-1].isFirstResponder = true
            for i in contentBlocks.indices {
                if i != index-1 {
                    contentBlocks[i].isFirstResponder = false
                }
            }
        } else {
            contentBlocks[index-1].isFirstResponder = true
            for i in contentBlocks.indices {
                if i != index-1 {
                    contentBlocks[i].isFirstResponder = false
                }
            }
        }
        focusedField = contentBlocks[index-1].id
        if index - 1 == 0 {
            isTitleSet = false
        }
    }
//    private func isWhiteSpaces(content: TextEditorContent) -> Bool {
//        switch content {
//        case .title(let contentText):
//            return contentText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//        case .subtitle(let contentText):
//            return contentText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
////        case .paragraph(let contentText):
////            return contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//        case .codeBlock(let contentText):
//            return contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//        default:
//            return false
//        }
//    }
}
