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
