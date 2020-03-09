//
//  ChatScrollView.swift
//  Crosstalk
//
//  Created by Scott Gardner on 1/22/20.
//  Copyright © 2020 Scott Gardner. All rights reserved.
//

import SwiftUI

struct ChatScrollView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.messages) {
                    MessageView(message: $0)
                }
            }
        }
    }
}

struct ChatScrollView_Previews: PreviewProvider {
    static var previews: some View {
        ChatScrollView()
            .environmentObject(ChatViewModel())
    }
}
