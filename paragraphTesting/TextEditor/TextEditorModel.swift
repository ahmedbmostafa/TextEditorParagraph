//
//  TextEditorModel.swift
//  paragraphTesting
//
//  Created by Ahmed beddah on 12/09/2025.
//

import UIKit

struct TextEditorModel: Identifiable, Equatable {
    var id: UUID
    var trackedID: UUID = UUID()
    var textHeight: CGFloat
    var textWidth: Int = 50
    var textFont: UIFont
    var content: TextEditorContent
    var contentOrder: Int
    var isFirstResponder: Bool
    var isTitleSet: Bool
    var imageUUID: UUID = UUID()
    var isImageAlt: Bool = false
    var imageDetails: [TextEditorImageModel] = []
    var textMarkups: [UUID : [MarkupModel]] = [:]
    var linkAttributes = [NSAttributedString.Key : Any]()
    
    func hasChanged(comparedTo other: TextEditorModel) -> Bool {
          return self.content != other.content
      }
}

enum TextEditorContent: Hashable {
    case mainTitle(String)
    case title(NSAttributedString)
    case subtitle(NSAttributedString)
    case paragraph(NSAttributedString)
    case codeBlock(String)
    case orderedList(NSAttributedString)
    case bulletedList(NSAttributedString)
    case quote(NSAttributedString)
    case highlightedQuote(NSAttributedString)
    case lineBreak(String)
    case divider(String)
    case image(UIImage)
    case video(String)
    case empty(String)
}

extension TextEditorModel {
    func extractAttributedString(content: TextEditorContent) -> NSAttributedString {
        switch content {
        case .title(let textValue):
            return textValue
        case .subtitle(let textValue):
            return textValue
        case .paragraph(let textValue):
            return textValue
        case .orderedList(let listText):
            return listText
        case .bulletedList(let listText):
            return listText
        case .quote(let textValue):
            return textValue
        case .highlightedQuote(let textValue):
            return textValue
        default:
            return NSAttributedString()
        }
    }
}

extension TextEditorModel {
    func extractText(content: TextEditorContent) -> String {
        switch content {
        case .mainTitle(let textValue):
            return textValue
        case .title(let textValue):
            return textValue.string
        case .subtitle(let textValue):
            return textValue.string
        case .paragraph(let textValue):
            return textValue.string
        case .codeBlock(let codeText):
            return codeText
        case .orderedList(let listText):
            return listText.string
        case .bulletedList(let listText):
            return listText.string
        case .quote(let textValue):
            return textValue.string
        case .highlightedQuote(let textValue):
            return textValue.string
        case .lineBreak(let textValue):
            return textValue
        case .divider(let textValue):
            return textValue
        case .video(let videoURL):
            return videoURL
        default:
            return ""
        }
    }
}

extension TextEditorModel {
    func getComponentType() -> String {
        switch content {
        case .mainTitle:
            return "title"
        case .title:
            return "title"
        case .subtitle:
            return "subtitle"
        case .paragraph:
            return "paragraph"
        case .codeBlock:
            return "code_block"
        case .orderedList:
            return "ordered_list_item"
        case .bulletedList:
            return "unordered_list_item"
        case .quote:
            return "quote"
        case .highlightedQuote:
            return "highlighted_quote"
        case .lineBreak:
            return "line_break"
        case .divider:
            return "horizontal_line"
        case .image:
            return "image"
        case .video:
            return "video"
        case .empty:
            return "empty"
        }
    }
}

extension TextEditorModel: Hashable {
      public func hash(into hasher: inout Hasher) {
          return hasher.combine(id)
      }
      
      public static func == (lhs: TextEditorModel, rhs: TextEditorModel) -> Bool {
          return lhs.id == rhs.id
      }
}

struct TextEditorImageModel {
    var id: UUID
    var altValue: String = ""
    var captionValue: String = ""
    var isImageAlt: Bool = false
    
    func hasChanged(comparedTo other: TextEditorImageModel) -> Bool {
          return self.captionValue != other.captionValue || self.altValue != other.altValue
      }
}

struct MarkupModel: Codable {
    var type: String
    var from, to: Int
    var url: String? = ""
}
