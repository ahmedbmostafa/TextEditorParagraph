//
//  TextEditorView.swift
//  paragraphTesting
//
//  Created by Ahmed beddah on 12/09/2025.
//

import SwiftUI

struct TextEditorView: View {
    
    // MARK: - Properties
    
    @StateObject var viewModel = TextEditorViewModel()
    @State var isTitleSet = false
    @State var showChip = false
    
    // MARK: - Body
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            Color.blue.opacity(0.01)
                .ignoresSafeArea()
            
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach($viewModel.contentBlocks.indices, id: \.self) { index in
                            let block = viewModel.contentBlocks[index]
                            switch block.content {
                            case .paragraph(let text):
                                ParagraphBlockView(block: $viewModel.contentBlocks[index], textValue: text, isTitleSet: $isTitleSet, scrollViewProxy: scrollViewProxy)
                                    .environmentObject(viewModel)
                                    .padding(.bottom, 16)
                            default:
                                Text("")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(20)
                .onTapGesture {
                    viewModel.insertParagraphBlock()
                }
            }
            
            if showChip {
                    HStack(alignment: .center) {
                        Spacer()
                        
                        if viewModel.markedType == "title" || viewModel.markedType == "subtitle" {
                            HStack(alignment: .center, spacing: 8) {
                                Image("link_markup")
                                    .resizable()
                                    .frame(width: 26, height: 26)
                                    .padding(.leading, 12)
                                
                                Text("hyper_link_")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.black)
                                    .padding(.trailing, 12)
                            }
                            .frame(height: 42)
//                            .background(Color.surfaceBG)
                            .cornerRadius(8)
                            .onChange(of: viewModel.showMarkupsMenu) { showMarkupsMenu in
                                if !showMarkupsMenu {
                                    if let index = viewModel.contentBlocks.firstIndex(where: { $0.id == viewModel.selectedBodySectionUUID }) {
                                        viewModel.contentBlocks[index].isFirstResponder = true
                                    }
                                }
                            }
                            .onTapGesture {
                                if viewModel.selectedBodySectionUUID != nil {
                                    if let index = viewModel.contentBlocks.firstIndex(where: { $0.id == viewModel.selectedBodySectionUUID }) {
                                        viewModel.contentBlocks[index].isFirstResponder = false
                                    }
                                }
                                viewModel.showMarkupsMenu = true
                            }
                            .frame(height: 58)
                            
                        } else {
                            HStack(alignment: .center, spacing: 8) {
                                Image("bold_markup")
                                    .resizable()
                                    .frame(width: 26, height: 26)
                                    .padding(.leading, 12)
                                
                                Text("bold_")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.black)
                                    .padding(.trailing, 12)
                            }
                            .frame(height: 42)
//                            .background(Color.surfaceBG)
                            .cornerRadius(8)
                            .onTapGesture {
                                viewModel.applySelectedMarkup(markupType: "bold", markupFont: UIFont.systemFont(ofSize: 20, weight: .bold))
                            }
                            
                                Spacer()
                                
                                HStack(alignment: .center, spacing: 8) {
                                    Image("italic_markup")
                                        .resizable()
                                        .frame(width: 26, height: 26)
                                        .padding(.leading, 12)
                                    
                                    Text("italic_")
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundColor(Color.black)
                                        .padding(.trailing, 12)
                                }
                                .frame(height: 42)
//                                .background(Color.surfaceBG)
                                .cornerRadius(8)
                                .onTapGesture {
                                    viewModel.applySelectedMarkup(markupType: "italic", markupFont: UIFont.systemFont(ofSize: 20, weight: .light))
                                }
                            
                            
                            Spacer()
                            
                            HStack(alignment: .center, spacing: 8) {
                                Image("link_markup")
                                    .resizable()
                                    .frame(width: 26, height: 26)
                                    .padding(.leading, 12)
                                
                                Text("hyper_link_")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color.black)
                                    .padding(.trailing, 12)
                            }
                            .frame(height: 42)
//                            .background(Color.surfaceBG)
                            .cornerRadius(8)
                            .onChange(of: viewModel.showMarkupsMenu) { showMarkupsMenu in
                                if !showMarkupsMenu {
                                    if let index = viewModel.contentBlocks.firstIndex(where: { $0.id == viewModel.selectedBodySectionUUID }) {
                                        viewModel.contentBlocks[index].isFirstResponder = true
                                    }
                                }
                            }
                            .onTapGesture {
                                if viewModel.selectedBodySectionUUID != nil {
                                    if let index = viewModel.contentBlocks.firstIndex(where: { $0.id == viewModel.selectedBodySectionUUID }) {
                                        viewModel.contentBlocks[index].isFirstResponder = false
                                    }
                                }
                                viewModel.showMarkupsMenu = true
                            }
                            .frame(height: 58)
                        }
                        
                        Spacer()
                    }
            }
        }
        .onChange(of: viewModel.highlightedText) { highlightedText in
            if highlightedText == "" || highlightedText == nil {
                showChip = false
            } else {
                showChip = true
            }
        }
        .onAppear {
            viewModel.insertParagraphBlock()
        }
    }
}
struct ParagraphBlockView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var textEditorViewModel: TextEditorViewModel
    @Binding var block: TextEditorModel
    @State var textValue: NSAttributedString
    @Binding var isTitleSet: Bool
    @State var scrollViewProxy: ScrollViewProxy
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if textEditorViewModel.contentBlocks.count > 1 {
                if case .paragraph(_) = textEditorViewModel.contentBlocks[1].content {
                    if block.extractAttributedString(content: block.content).string.isEmpty && block == textEditorViewModel.contentBlocks[1] {
                        Text("start_typing")
                            .foregroundColor(Color.black.opacity(0.10))
                            .font(.title)
                            .onTapGesture {
                                block.isFirstResponder = true
                            }
                    }
                }
            }
            
            ParagraphBlockWrapper(
                isFirstResponder: $block.isFirstResponder,
                textValue: Binding(
                    get: { textValue },
                    set: { newValue in
                        textEditorViewModel.updateParagraphText(for: block.id, newValue: newValue)
                    }
                ),
                textFont: $block.textFont,
                isTitleSet: $isTitleSet,
                contentBlock: $block,
                onDeleteBackward: { textEditorViewModel.handleDeleteAction(for: block.id) },
                scrollViewProxy: scrollViewProxy,
                onReturnTapped: { textEditorViewModel.insertParagraphBlock() }
            )
            .environmentObject(textEditorViewModel)
            .frame(height: CGFloat(block.textHeight))
            .id(block.trackedID)
        }
        .onTapGesture {}
        .onChange(of: block.textHeight) { textHeight in
            print("textHeight==", textHeight)
        }
    }
}
