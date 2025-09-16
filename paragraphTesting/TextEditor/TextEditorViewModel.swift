//
//  TextEditorViewModel.swift
//  Quillki
//
//  Created by Nixope on 08/09/2024.
//

import SwiftUI
import Combine
import NaturalLanguage

class TextEditorViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var contentBlocks: [TextEditorModel] = []
    @Published var oldContentBlocks: [TextEditorModel] = []
    @Published var isFirstResponder = false
    @Published var cursorIndex = -1
    @Published var scrollToBlock = UUID()
    @Published var isTitleSet = false
    @Published var isCodeBlock = false
    @Published var showImagePicker = false
    @Published var section: [String: Any] = [:]
    @Published var orderListDict: [UUID: (count: Int, value: String)] = [:]
    @Published var bulletedListDict: [UUID: (count: Int, value: String)] = [:]
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
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        
    }
}

// MARK: - MainTitleBlock

extension TextEditorViewModel {
    func insertMainTitleBlock() {
        let titleBlock = TextEditorModel(id: UUID(), textHeight: 52, textFont: UIFont.systemFont(ofSize: 30, weight: .bold), content: .mainTitle(""), contentOrder: 0, isFirstResponder: false, isTitleSet: true)
        let emptyBlock = TextEditorModel(id: UUID(), textHeight: 300, textFont: UIFont.systemFont(ofSize: 10, weight: .regular), content: .empty(""), contentOrder: 0, isFirstResponder: false, isTitleSet: true)
        if case .empty(_) = contentBlocks.last?.content {
            contentBlocks.removeLast()
        }
        contentBlocks.append(titleBlock)
        contentBlocks.append(emptyBlock)
        cursorIndex = 0
        insertParagraphBlock(isFirstResponder: false)
    }
    
    func updateMainTitleText(for blockId: UUID, newValue: String) {
        if let index = contentBlocks.firstIndex(where: { $0.id == blockId }) {
            contentBlocks[index].isFirstResponder = true
            contentBlocks[index].content = .mainTitle(newValue)
            contentBlocks[index].textHeight = calculateTextHeight(text: newValue, width: UIScreen.main.bounds.width - 40, textFont: contentBlocks[index].textFont, marginHeight: 10)
            updateFirstResponder(newBlockID: blockId)
        }
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

// MARK: - TitleBlock

extension TextEditorViewModel {
    
    func overridBlock(type: TextEditorContent) {
        guard let index = contentBlocks.firstIndex(where: {$0.id == currentBlockID}) else {return}
        var overrideBlock: TextEditorModel?
        var textHeight: CGFloat?
        let currentType = contentBlocks[index].content
        
        switch type {
        case .orderedList:
            let blockToCheck = contentBlocks[index]
            if case .orderedList(_) = blockToCheck.content {
                return
            }
            handleListType(currentType)
            self.checkOrderedListSequence(before: cursorIndex + 1, body: contentBlocks) {
                let attributedString = self.createAttributedString(
                    text: "\(self.currentListNumber + 1). \(self.currentBlockValue)",
                    fontSize: 20,
                    color: UIColor.black
                )
                textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 80, textFont: self.contentBlocks[index].textFont, marginHeight: 10)
                overrideBlock = TextEditorModel(id: self.currentBlockID, textHeight: textHeight ?? 0.0, textFont: UIFont.systemFont(ofSize: 20, weight: .regular), content: .orderedList(attributedString), contentOrder: self.contentBlocks[index].contentOrder, isFirstResponder: true, isTitleSet: true)
            }
        case .bulletedList:
            handleListType(currentType)
            let attributedString = createAttributedString(
                text: "\u{2022} \(currentBlockValue)",
                fontSize: 20,
                color: UIColor.black
            )
            textHeight = calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 80, textFont: self.contentBlocks[index].textFont, marginHeight: 10)
            overrideBlock = TextEditorModel(id: currentBlockID, textHeight: textHeight  ?? 0.0, textFont: UIFont.systemFont(ofSize: 20, weight: .regular), content: .bulletedList(attributedString), contentOrder: contentBlocks[index].contentOrder, isFirstResponder: true, isTitleSet: true)
        case .title:
            handleListType(currentType)
            let attributedString = createAttributedString(text: currentBlockValue, font: UIFont.systemFont(ofSize: 28, weight: .bold))
            textHeight = calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 65, textFont: contentBlocks[index].textFont, marginHeight: 10)
            overrideBlock = TextEditorModel(id: currentBlockID, textHeight: textHeight ?? 0.0, textFont: UIFont.systemFont(ofSize: 28, weight: .bold), content: .title(attributedString), contentOrder: contentBlocks[index].contentOrder, isFirstResponder: true, isTitleSet: true)
        case .subtitle:
            handleListType(currentType)
            let attributedString = createAttributedString(text: currentBlockValue, font: UIFont.systemFont(ofSize: 24, weight: .bold))
            textHeight = calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 60, textFont: contentBlocks[index].textFont, marginHeight: 10)
            overrideBlock = TextEditorModel(id: currentBlockID, textHeight: textHeight ?? 0.0, textFont: UIFont.systemFont(ofSize: 24, weight: .bold), content: .subtitle(attributedString), contentOrder: contentBlocks[index].contentOrder, isFirstResponder: true, isTitleSet: true)
        case .quote:
            handleListType(currentType)
            let attributedString = createAttributedString(text: currentBlockValue)
            textHeight = calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 80, textFont: contentBlocks[index].textFont, marginHeight: 10)
            overrideBlock = TextEditorModel(id: currentBlockID, textHeight: textHeight ?? 0.0, textFont: UIFont.systemFont(ofSize: 20, weight: .regular), content: .quote(attributedString), contentOrder: contentBlocks[index].contentOrder, isFirstResponder: true, isTitleSet: true)
        case .highlightedQuote:
            handleListType(currentType)
            let attributedString = createAttributedString(text: currentBlockValue)
            textHeight = calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 112, textFont: contentBlocks[index].textFont, marginHeight: 50)
            overrideBlock = TextEditorModel(id: currentBlockID, textHeight: textHeight ?? 0.0, textFont: UIFont.systemFont(ofSize: 20, weight: .regular), content: .highlightedQuote(attributedString), contentOrder: contentBlocks[index].contentOrder, isFirstResponder: true, isTitleSet: true)
        default:
            break
        }
        
        overrideBlock?.trackedID = UUID()
        guard let overrideBlock = overrideBlock else {return}
        contentBlocks.remove(at: index)
        self.contentBlocks.insert(overrideBlock, at: index)
    }
    
    func handleListType(_ type: TextEditorContent) {
        if case .orderedList(_) = type {
            currentBlockValue = String(currentBlockValue.dropFirst(3))
        }
        
        if case .bulletedList(_) = type {
            currentBlockValue = String(currentBlockValue.dropFirst(2))
        }
    }
    
    private func checkOrderedListSequence(before index: Int, body: [TextEditorModel], completion: @escaping () -> Void) {
        guard index >= 0 && index < body.count else { return }
        let blockToCheck = contentBlocks[index-2]
        if case .orderedList(_) = blockToCheck.content {
            currentListNumber = orderedListNumber(from: blockToCheck.extractAttributedString(content: blockToCheck.content).string) ?? 0
        }
        completion()
    }
    
    private func orderedListNumber(from text: String) -> Int? {
        let pattern = #"^(\d+)\."#  // start of string, one or more digits, then a dot
        if let match = text.range(of: pattern, options: .regularExpression) {
            let numberPart = text[match].dropLast() // remove the "."
            return Int(numberPart)
        }
        return nil
    }
    
    func insertTitleBlock(text: String = "", isFirstResponder: Bool = true, markups: [MarkupModel] = []) {
        let attributedString = createAttributedString(text: text, font: UIFont.systemFont(ofSize: 28, weight: .bold))
        let newTextBlock = TextEditorModel(id: UUID(), textHeight: 50, textFont: UIFont.systemFont(ofSize: 28, weight: .bold), content: .title(attributedString), contentOrder: cursorIndex + 1, isFirstResponder: true, isTitleSet: true)
        let emptyBlock = TextEditorModel(id: UUID(), textHeight: 300, textFont: UIFont.systemFont(ofSize: 10, weight: .regular), content: .empty(""), contentOrder: 0, isFirstResponder: false, isTitleSet: true)
        if case .empty(_) = contentBlocks[contentBlocks.count-1].content {
            contentBlocks.remove(at: contentBlocks.count-1)
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
        if scrollViewProxy != nil {
            scrollToLastBlock(with: scrollViewProxy!)
        }
//        createBodySection(component: newTextBlock)
        applyMarkupWithInsertion(markups: markups, blockId: newTextBlock.id, attributedString: attributedString)
        isTitleSet = true
        updateFirstResponder(newBlockID: newTextBlock.id)
    }
    
    func updateTitleText(for blockId: UUID, newValue: NSAttributedString, updateCursor: Bool = true, newMarkups: [MarkupModel] = []) {
        updateTextBlockContent(blockId, newValue, font: UIFont.systemFont(ofSize: 28, weight: .bold), contentType: .title(newValue), marginHeight: 10, updateCursor: updateCursor, newMarkups: newMarkups)
    }
}

// MARK: - SubtitleBlock

extension TextEditorViewModel {
    func insertSubtitleBlock(text: String = "", isFirstResponder: Bool = true, markups: [MarkupModel] = []) {
        let attributedString = createAttributedString(text: text, font: UIFont.systemFont(ofSize: 24, weight: .bold))
        let newTextBlock = TextEditorModel(id: UUID(), textHeight: 38, textFont: UIFont.systemFont(ofSize: 24, weight: .bold), content: .subtitle(attributedString), contentOrder: cursorIndex + 1, isFirstResponder: true, isTitleSet: true)
        let emptyBlock = TextEditorModel(id: UUID(), textHeight: 300, textFont: UIFont.systemFont(ofSize: 10, weight: .bold), content: .empty(""), contentOrder: 0, isFirstResponder: false, isTitleSet: true)
        if case .empty(_) = contentBlocks[contentBlocks.count-1].content {
            contentBlocks.remove(at: contentBlocks.count-1)
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
        if scrollViewProxy != nil {
            scrollToLastBlock(with: scrollViewProxy!)
        }
//        createBodySection(component: newTextBlock)
        applyMarkupWithInsertion(markups: markups, blockId: newTextBlock.id, attributedString: attributedString)
        isTitleSet = true
        updateFirstResponder(newBlockID: newTextBlock.id)
    }
    
    func updateSubtitleText(for blockId: UUID, newValue: NSAttributedString, updateCursor: Bool = true, newMarkups: [MarkupModel] = []) {
        updateTextBlockContent(blockId, newValue, font: UIFont.systemFont(ofSize: 24, weight: .bold), contentType: .subtitle(newValue), marginHeight: 10, updateCursor: updateCursor, newMarkups: newMarkups)
    }
}

// MARK: - CodeBlock

extension TextEditorViewModel {
    func insertCodeBlock() {
        isInOrderedList = false
        currentListNumber = 0
        if contentBlocks.count >= 2 {
        } else {
            cursorIndex = 1
        }
        let newCodeBlock = TextEditorModel(id: UUID(), textHeight: 50, textWidth: Int(UIScreen.main.bounds.width-40), textFont: UIFont.systemFont(ofSize: 14, weight: .regular), content: .codeBlock(""), contentOrder: cursorIndex + 1, isFirstResponder: false, isTitleSet: true)
        focusedField = newCodeBlock.id
        let emptyBlock = TextEditorModel(id: UUID(), textHeight: 300, textFont: UIFont.systemFont(ofSize: 10, weight: .regular), content: .empty(""), contentOrder: 0, isFirstResponder: false, isTitleSet: true)
        if case .empty(_) = contentBlocks[contentBlocks.count-1].content {
            contentBlocks.remove(at: contentBlocks.count-1)
        }
        if contentBlocks.count < cursorIndex + 1 {
            contentBlocks.append(newCodeBlock)
        } else {
            contentBlocks.insert(newCodeBlock, at: cursorIndex + 1)
        }
        if case .mainTitle(_) = contentBlocks.first?.content {
            contentBlocks = contentBlocks.enumerated().map { index, block in
                var updatedBlock = block
                updatedBlock.contentOrder = index
                return updatedBlock
            }
        }
        contentBlocks.append(emptyBlock)
        if scrollViewProxy != nil {
            scrollToLastBlock(with: scrollViewProxy!)
        }
//        createBodySection(component: newCodeBlock)
        isTitleSet = true
        updateFirstResponder(newBlockID: newCodeBlock.id)
    }
    
    func updateCodeBlockText(for blockId: UUID, newValue: String) {
        if let index = contentBlocks.firstIndex(where: { $0.id == blockId }) {
            cursorIndex = index
            contentBlocks[index].content = .codeBlock(newValue)
            contentBlocks[index].textWidth = Int(UIScreen.main.bounds.width-40)
            contentBlocks[index].textHeight = calculateCodeBlockTextHeight(text: newValue)
            updateFirstResponder(newBlockID: blockId)
        }
    }
}

// MARK: - OrderedListBlock

extension TextEditorViewModel {
    func insertOrderedListBlock(text: String = "", isFirstResponder: Bool = true, markups: [MarkupModel] = []) {
        let attributedString = createAttributedString(
            text: "\(currentListNumber + 1). \(text)",
            fontSize: 20,
            color: UIColor.black
        )
        let newTextBlock = createNewTextBlock(content: .orderedList(attributedString), isFirstResponder: true)
        applyMarkupWithInsertion(markups: markups, blockId: newTextBlock.id, attributedString: attributedString)
        updateFirstResponder(newBlockID: newTextBlock.id)
    }
    
    func updateOrderedListText(blockId: UUID, newValue: NSAttributedString, updateCursor: Bool = true, newMarkups: [MarkupModel] = []) {
        updateTextBlockContent(blockId, newValue, contentType: .orderedList(newValue), marginHeight: 10, updateCursor: updateCursor, newMarkups: newMarkups)
    }
}

// MARK: - BulltedListBlock

extension TextEditorViewModel {
    func insertBulltedListBlock(text: String = "", isFirstResponder: Bool = true, markups: [MarkupModel] = []) {
        let attributedString = createAttributedString(
            text: "\u{2022} \(text)",
            fontSize: 20,
            color: UIColor.black
        )
        let newTextBlock = createNewTextBlock(content: .bulletedList(attributedString), isFirstResponder: true)
        applyMarkupWithInsertion(markups: markups, blockId: newTextBlock.id, attributedString: attributedString)
        updateFirstResponder(newBlockID: newTextBlock.id)
    }
    
    func updateBulltedList(for blockId: UUID, newValue: NSAttributedString, updateCursor: Bool = true, newMarkups: [MarkupModel] = []) {
        if bulletedListDict[blockId] == nil {
            bulletedListDict[blockId] = (count: 1, value: newValue.string)
        }
        let currentOrder = bulletedListDict[blockId]!.count
        DispatchQueue.main.async {
            self.bulletedListDict[blockId] = (count: currentOrder, value: newValue.string)
        }
        updateTextBlockContent(blockId, newValue, contentType: .bulletedList(newValue), marginHeight: 10, updateCursor: updateCursor, newMarkups: newMarkups)
    }
}

// MARK: - QuoteBlock

extension TextEditorViewModel {
    func insertQuoteBlock() {
        let attributedString = createAttributedString()
        let newTextBlock = createNewTextBlock(content: .quote(attributedString), isFirstResponder: true)
        updateFirstResponder(newBlockID: newTextBlock.id)
    }
    
    func updateQuoteText(for blockId: UUID, newValue: NSAttributedString) {
        updateTextBlockContent(blockId, newValue, contentType: .quote(newValue), marginHeight: 10)
    }
}

// MARK: - HighlightedQuoteBlock

extension TextEditorViewModel {
    func insertHighlightedQuoteBlock() {
        let attributedString = createAttributedString()
        let newTextBlock = createNewTextBlock(content: .highlightedQuote(attributedString), isFirstResponder: true)
        updateFirstResponder(newBlockID: newTextBlock.id)
    }
    
    func updateHighlightedQuoteText(for blockId: UUID, newValue: NSAttributedString) {
        updateTextBlockContent(blockId, newValue, contentType: .highlightedQuote(newValue), marginHeight: 50)
    }
}

// MARK: - LineBreakBlock

extension TextEditorViewModel {
    func insertLineBreakBlock() {
        let lineBreakBlock = TextEditorModel(id: UUID(), textHeight: 20, textFont: UIFont.systemFont(ofSize: 10, weight: .regular), content: .lineBreak(""), contentOrder: cursorIndex + 1, isFirstResponder: false, isTitleSet: true)
        let emptyBlock = TextEditorModel(id: UUID(), textHeight: 300, textFont: UIFont.systemFont(ofSize: 10, weight: .regular), content: .empty(""), contentOrder: 0, isFirstResponder: false, isTitleSet: true)
        
        if case .empty(_) = contentBlocks[contentBlocks.count-1].content {
            contentBlocks.remove(at: contentBlocks.count-1)
        }
        if contentBlocks.count < cursorIndex + 1 {
            contentBlocks.append(lineBreakBlock)
        } else {
            contentBlocks.insert(lineBreakBlock, at: cursorIndex + 1)
        }
        if case .mainTitle(_) = contentBlocks.first?.content {
            contentBlocks = contentBlocks.enumerated().map { index, block in
                var updatedBlock = block
                updatedBlock.contentOrder = index
                return updatedBlock
            }
        }
        contentBlocks.append(emptyBlock)
        if scrollViewProxy != nil {
            scrollToLastBlock(with: scrollViewProxy!)
        }
//        createBodySection(component: lineBreakBlock)
        self.insertParagraphBlock()
    }
}

// MARK: - DividerBlock

extension TextEditorViewModel {
    func insertDividerBlock() {
        let dividerBlock = TextEditorModel(id: UUID(), textHeight: 38, textFont: UIFont.systemFont(ofSize: 20, weight: .regular), content: .divider(". . ."), contentOrder: cursorIndex + 1, isFirstResponder: false, isTitleSet: true)
        let emptyBlock = TextEditorModel(id: UUID(), textHeight: 300, textFont: UIFont.systemFont(ofSize: 10, weight: .regular), content: .empty(""), contentOrder: 0, isFirstResponder: false, isTitleSet: true)
        
        if case .empty(_) = contentBlocks[contentBlocks.count-1].content {
            contentBlocks.remove(at: contentBlocks.count-1)
        }
        if contentBlocks.count < cursorIndex + 1 {
            contentBlocks.append(dividerBlock)
        } else {
            contentBlocks.insert(dividerBlock, at: cursorIndex + 1)
        }
        if case .mainTitle(_) = contentBlocks.first?.content {
            contentBlocks = contentBlocks.enumerated().map { index, block in
                var updatedBlock = block
                updatedBlock.contentOrder = index
                return updatedBlock
            }
        }
        contentBlocks.append(emptyBlock)
        if scrollViewProxy != nil {
            scrollToLastBlock(with: scrollViewProxy!)
        }
//        createBodySection(component: dividerBlock)
        cursorIndex += 1
        self.insertParagraphBlock()
    }
}

// MARK: - ImageBlock

extension TextEditorViewModel {
    func insertImageBlock(image: UIImage, scrollViewProxy: ScrollViewProxy) {
        for i in (0..<contentBlocks.count).reversed() {
            contentBlocks[i].isFirstResponder = false
            if isWhiteSpaces(content: contentBlocks[i].content) {
                if i != 0 {
                    contentBlocks.remove(at: i)
                }
            }
        }
        
        var newImageBlock = TextEditorModel(id: UUID(), textHeight: 0, textFont: UIFont(), content: .image(image), contentOrder: cursorIndex + 1, isFirstResponder: false, isTitleSet: true)
        
        let emptyBlock = TextEditorModel(id: UUID(), textHeight: 300, textFont: UIFont.systemFont(ofSize: 10, weight: .regular), content: .empty(""), contentOrder: 0, isFirstResponder: false, isTitleSet: true)
        
        if case .empty(_) = contentBlocks[contentBlocks.count-1].content {
            contentBlocks.remove(at: contentBlocks.count-1)
        }
        if contentBlocks.count < cursorIndex + 1 {
            unsplashImageDetails.id = newImageBlock.imageUUID
            newImageBlock.imageDetails.append(unsplashImageDetails)
            contentBlocks.append(newImageBlock)
        } else {
            unsplashImageDetails.id = newImageBlock.imageUUID
            newImageBlock.imageDetails.append(unsplashImageDetails)
            contentBlocks.insert(newImageBlock, at: cursorIndex + 1)
        }
        cursorIndex += 1
        if case .mainTitle(_) = contentBlocks.first?.content {
            contentBlocks = contentBlocks.enumerated().map { index, block in
                var updatedBlock = block
                updatedBlock.contentOrder = index
                return updatedBlock
            }
        }
        contentBlocks.append(emptyBlock)
        guard let data = image.pngData() else {return}
//        uploadImage(imageData: data, component: newImageBlock)
        if let index = contentBlocks.firstIndex(where: { $0.id == newImageBlock.id }) {
            if index == 1 {
                isTitleSet = false
            }
        }
        scrollToLastBlock(with: scrollViewProxy)
    }
}


extension TextEditorViewModel {
    private func createAttributedString(text: String = "", font: UIFont? = nil, fontSize: CGFloat = 20, color: UIColor = UIColor.black) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let totalLength = attributedString.string.utf16.count
        let range = NSRange(location: 0, length: totalLength)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        
        if font != nil {
            attributedString.addAttribute(.font, value: font, range: range)
        } else {
            let font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
            attributedString.addAttribute(.font, value: font, range: range)
        }
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
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
            handleCustomHeight(index: contentBlocks.count-1)
        } else {
            contentBlocks.insert(newTextBlock, at: cursorIndex + 1)
            handleCustomHeight(index: cursorIndex + 1)
        }
        if case .mainTitle(_) = contentBlocks.first?.content {
            contentBlocks = contentBlocks.enumerated().map { index, block in
                var updatedBlock = block
                updatedBlock.contentOrder = index
                return updatedBlock
            }
        }
        contentBlocks.append(emptyBlock)
        if scrollViewProxy != nil {
            scrollToLastBlock(with: scrollViewProxy!)
        }
//        createBodySection(component: newTextBlock)
        return newTextBlock
    }
    
    func trackCurrentBlock(blockIndex: Int) {
        let blockID = contentBlocks[blockIndex].id
        let blockText = contentBlocks[blockIndex].extractText(content: contentBlocks[blockIndex].content)
        DispatchQueue.main.async {
            self.currentBlockID = blockID
            self.currentBlockValue = blockText
        }
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
                    self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 65, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(marginHeight))
                case .subtitle:
                    self.contentBlocks[index].content = .subtitle(attributedString)
                    self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 60, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(marginHeight))
                case .paragraph:
                    self.contentBlocks[index].content = .paragraph(attributedString)
                    self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 60, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(marginHeight))
                case .orderedList:
                    self.contentBlocks[index].content = .orderedList(attributedString)
                    self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 80, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(marginHeight))
                case .bulletedList:
                    self.contentBlocks[index].content = .bulletedList(attributedString)
                    self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 80, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(marginHeight))
                case .quote:
                    self.contentBlocks[index].content = .quote(attributedString)
                    self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 80, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(marginHeight))
                case .highlightedQuote:
                    self.contentBlocks[index].content = .highlightedQuote(attributedString)
                    self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 112, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(marginHeight))
                default:
                    break
                }
                
               
                
                if updateCursor {
                    self.updateFirstResponder(newBlockID: blockId)
                }
            }
        }
    }
    
    private func handleCustomHeight(index: Int) {
        let contentType = contentBlocks[index].content
        let attributedString = contentBlocks[index].extractAttributedString(content: contentType)
        switch contentType {
        case .title:
            self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 65, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(10))
        case .subtitle:
            self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 60, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(10))
        case .paragraph:
            self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 60, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(10))
        case .orderedList:
            self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 80, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(10))
        case .bulletedList:
            self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 80, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(10))
        case .quote:
            self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 80, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(10))
        case .highlightedQuote:
            self.contentBlocks[index].textHeight = self.calculateTextHeightQuote(text: attributedString, width: UIScreen.main.bounds.width - 112, textFont: self.contentBlocks[index].textFont, marginHeight: CGFloat(50))
        default:
            break
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
            let font = UIFont.systemFont(ofSize: 20, weight: .light)
            attributedString.addAttribute(.font, value: font, range: markupRange)
        case "bold":
            let font = UIFont.systemFont(ofSize: 20, weight: .bold)
            attributedString.addAttribute(.font, value: font, range: markupRange)
        case "bolditalic":
            let font = UIFont.systemFont(ofSize: 20, weight: .heavy)
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
                    return UIFont.systemFont(ofSize: baseFont.pointSize - 1.0, weight: .heavy)
                } else if isItalic {
                    trackedMarkupType = ""
                    return UIFont.systemFont(ofSize: baseFont.pointSize - 1.0, weight: .regular)
                }
            case "bold":
                if isBold {
                    trackedMarkupType = ""
                    return UIFont.systemFont(ofSize: baseFont.pointSize - 1.0, weight: .regular)
                } else if isItalic {
                    trackedMarkupType = "bolditalic"
                    return UIFont.systemFont(ofSize: baseFont.pointSize - 1.0, weight: .heavy)
                }
            case "bolditalic":
                if isBold {
                    trackedMarkupType = "italic"
                    return UIFont.systemFont(ofSize: baseFont.pointSize - 1.0, weight: .light)
                } else if isItalic {
                    trackedMarkupType = "bold"
                    return UIFont.systemFont(ofSize: baseFont.pointSize - 1.0, weight: .bold)
                }
            default:
                break
            }
        } else {
            if isBold && isItalic {
                trackedMarkupType = "bolditalic"
                return UIFont.systemFont(ofSize: baseFont.pointSize - 1.0, weight: .heavy)
            } else if isBold {
                trackedMarkupType = "bold"
                return UIFont.systemFont(ofSize: baseFont.pointSize - 1.0, weight: .bold)
            } else if isItalic {
                trackedMarkupType = "italic"
                return UIFont.systemFont(ofSize: baseFont.pointSize - 1.0, weight: .light)
            } else {
                trackedMarkupType = ""
                return UIFont.systemFont(ofSize: baseFont.pointSize - 1.0, weight: .regular)
            }
        }
        return UIFont.systemFont(ofSize: baseFont.pointSize - 1.0, weight: .regular)
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
}

// MARK: - Helper

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
//                    deleteArticleBodySection(component: contentBlocks[index])
//                    deleteArticleBodySection(component: contentBlocks[index - 1])
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
//                    deleteArticleBodySection(component: contentBlocks[index])
//                    deleteArticleBodySection(component: contentBlocks[index - 1])
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
//                    deleteArticleBodySection(component: contentBlocks[index])
//                    deleteArticleBodySection(component: contentBlocks[index - 1])
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
//                    deleteArticleBodySection(component: contentBlocks[index])
                    contentBlocks.remove(at: index)
                    adjustFocusAfterDelete(index: index)
                default:
//                    deleteArticleBodySection(component: contentBlocks[index])
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
    
    func scrollToLastBlock(with scrollViewProxy: ScrollViewProxy) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            if let lastBlockId = self.contentBlocks.last?.trackedID,
//               self.contentBlocks.contains(where: { $0.trackedID == lastBlockId }) {
//                DispatchQueue.main.async {
//                    withAnimation {
//                        scrollViewProxy.scrollTo(lastBlockId)
//                    }
//                }
//            }
//        }
    }
    
    private func isWhiteSpaces(content: TextEditorContent) -> Bool {
        switch content {
        case .title(let contentText):
            return contentText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .subtitle(let contentText):
            return contentText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//        case .paragraph(let contentText):
//            return contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .codeBlock(let contentText):
            return contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return false
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
        return height
    }
    
    private func calculateTextHeight(text: String, width: CGFloat, textFont: UIFont, marginHeight: CGFloat) -> CGFloat {
        let boundingSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        
        let attributedText = NSAttributedString(string: text, attributes: [.font: textFont])
        
        let boundingRect = attributedText.boundingRect(
            with: boundingSize,
            options: options,
            context: nil
        )
        
        return ceil(boundingRect.height) + marginHeight
    }
    
    func calculateCodeBlockTextWidth(text: String) -> CGFloat {
        let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return ceil(size.width + 10)
    }
    
    func calculateCodeBlockTextHeight(text: String) -> CGFloat {
        let textView = CustomTextView()
        textView.text = text
        textView.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        let newSize = textView.sizeThatFits(
            CGSize(width: UIScreen.main.bounds.width - 40,
                   height: CGFloat.greatestFiniteMagnitude)
        )
        let lines = calculateWrappedLines(textView: textView)
        return max(40, ceil(newSize.height + 20 - adjustment(for: lines)))
    }
    
    func adjustment(for lines: Int) -> CGFloat {
        switch lines {
        case 0..<8:   return CGFloat(lines) * 12
        case 8..<15:  return CGFloat(lines) * 10
        case 15..<25: return CGFloat(lines) * 9
        case 25..<40: return CGFloat(lines) * 8
        default:      return CGFloat(lines) * 7
        }
    }
    
    func calculateWrappedLines(textView: UITextView) -> Int {
        let textStorage = NSTextStorage(string: textView.text, attributes: [.font: textView.font])
        let textContainer = NSTextContainer(size: CGSize(width: UIScreen.main.bounds.width-40, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = 0
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Force layout
        layoutManager.ensureLayout(for: textContainer)

        var numberOfLines = 0
        var index = 0
        var lineRange = NSRange()

        while index < layoutManager.numberOfGlyphs {
            layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            numberOfLines += 1
            index = NSMaxRange(lineRange)
        }

        return numberOfLines
    }
    
    var userPlaceHolderImageValue: String {
        "user_placeholder"
    }
    
    var isValidContentBlocksCount: Bool {
        contentBlocks.count > 1
    }
    
    var greaterContent: TextEditorContent {
        contentBlocks[contentBlocks.count-2].content
    }
    
    var smallerContent: TextEditorContent {
        if contentBlocks.count == 1 {
            return contentBlocks[contentBlocks.count-1].content
        } else {
            return TextEditorContent.paragraph(NSAttributedString(string: ""))
        }
    }
    
    func isValidURL(_ urlString: String) -> Bool {
        let normalized = normalizeURL(urlString)
        guard let url = URL(string: normalized) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    func normalizeURL(_ urlString: String) -> String {
        let lowercased = urlString.lowercased()
        if lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://") {
            return urlString
        } else if lowercased.hasPrefix("www.") {
            return "https://\(urlString)"
        } else {
            return "https://www.\(urlString)"
        }
    }
}
extension UITextView {
    var numberOfLines: Int {
        guard let font = self.font else { return 0 }
        let layoutManager = self.layoutManager
        let textContainer = self.textContainer
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        
        var numberOfLines = 0
        var index = glyphRange.location
        
        while index < NSMaxRange(glyphRange) {
            var lineRange = NSRange(location: 0, length: 0)
            layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange)
            numberOfLines += 1
        }
        
        return numberOfLines
    }
}

extension UITextView {
    var visualLineCount: Int {
//        guard let layoutManager = self.layoutManager else { return 0 }
        
        var lineCount = 0
        var index = 0
        let text = self.text as NSString
        let numberOfGlyphs = layoutManager.numberOfGlyphs
        
        while index < numberOfGlyphs {
            var lineRange = NSRange()
            layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange)
            lineCount += 1
        }
        
        return lineCount
    }
}

extension UITextView {
    var wrappedLineCount: Int {
        guard let font = self.font else { return 0 }
        
        // Force layout so layoutManager has correct info
        self.layoutManager.ensureLayout(for: self.textContainer)
        
        let textStorage = self.textStorage
        let layoutManager = self.layoutManager
        let textContainer = self.textContainer
        
        var numberOfLines = 0
        var index = 0
        var lineRange = NSRange(location: 0, length: 0)
        
        while index < layoutManager.numberOfGlyphs {
            layoutManager.lineFragmentUsedRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange)
            numberOfLines += 1
        }
        
        return numberOfLines
    }
}


func getAppLang() -> String {
    return Locale.current.language.languageCode?.identifier ?? ""
}

func detectLanguage(text: String) -> String {
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    if let language = recognizer.dominantLanguage {
        return language.rawValue
    } else {
        return "Unknown language"
    }
}
