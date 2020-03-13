//
//  ReversibleChatScrollView.swift
//  Crosstalk
//
//  Created by Scott Gardner on 1/20/20.
//  Copyright © 2020 Scott Gardner. All rights reserved.
//

import SwiftUI

/*
 Credit:
 https://stackoverflow.com/a/58708206/616764
 https://blog.process-one.net/writing-a-custom-scroll-view-with-swiftui-in-a-chat-application/
 */
struct ReversibleChatScrollView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    
    let colorScheme: ColorScheme
    var reversed: Bool = false
    var scrollToEnd: Bool = false
    
    @State private var contentHeight: CGFloat = .zero
    @State private var contentOffset: CGFloat = .zero
    @State private var scrollOffset: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ForEach(self.viewModel.messages) {
                    MessageView(message: $0, isTranslating: self.$viewModel.isTranslating)
                }
            }
            .modifier(ViewHeightKey())
            .onPreferenceChange(ViewHeightKey.self) { value in
                self.updateHeight(with: value, outerHeight: geometry.size.height)
            }
            .frame(height: geometry.size.height, alignment: self.reversed ? .bottom : .top)
            .offset(y: self.contentOffset + self.scrollOffset)
            .animation(.easeInOut)
            .background(self.colorScheme == .dark ? Color.black : Color.white)
            .gesture(
                DragGesture()
                    .onChanged { self.onDragChanged($0) }
                    .onEnded { self.onDragEnded($0, outerHeight: geometry.size.height) }
            )
        }
    }
    
    private func updateHeight(with height: CGFloat, outerHeight: CGFloat) {
        let delta = contentHeight - height
        contentHeight = height
        
        if scrollToEnd {
            contentHeight = reversed ? height - outerHeight - delta : outerHeight - height
        }
        
        if abs(contentOffset) > .zero {
            updateOffset(with: delta, outerHeight: outerHeight)
        }
    }
    
    private func updateOffset(with offset: CGFloat, outerHeight: CGFloat) {
        let topLimit = contentHeight - outerHeight
        
        if topLimit < .zero {
            contentOffset = .zero
        } else {
            var proposedOffset = (contentOffset + offset) * (reversed ? 1 : -1)
            
            if proposedOffset < .zero {
                proposedOffset = .zero
            } else if proposedOffset > topLimit {
                proposedOffset = reversed ? topLimit : -topLimit
            }
            
            contentOffset = proposedOffset
        }
    }
    
    private func onDragChanged(_ value: DragGesture.Value) {
        scrollOffset = value.location.y - value.startLocation.y
    }
    
    private func onDragEnded(_ value: DragGesture.Value, outerHeight: CGFloat) {
        updateOffset(with: value.predictedEndLocation.y - value.startLocation.y, outerHeight: outerHeight)
        scrollOffset = 0
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { .zero }
    
    static func reduce(value: inout CGFloat, nextValue: () -> Value) {
        value += nextValue()
    }
}

extension ViewHeightKey: ViewModifier {
    func body(content: Content) -> some View {
        content.background(GeometryReader { geometry in
            Color.clear.preference(key: Self.self, value: geometry.size.height)
        })
    }
}
