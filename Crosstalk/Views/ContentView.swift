//
//  ContentView.swift
//  Crosstalk
//
//  Created by Scott Gardner on 1/15/20.
//  Copyright © 2020 Scott Gardner. All rights reserved.
//

import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var showActionSheet = false
    
    private let formatter = DateFormatter(dateStyle: .short, timeStyle: .short)
    
    var body: some View {
        NavigationView {
            VStack {
                ChatScrollView()
                
                ToolbarView(showActionSheet: $showActionSheet)
                    .padding()
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .offset(y: viewModel.keyboardOffset)
                    .animation(.easeInOut(duration: viewModel.keyboardAnimationDuration))
            }
            .animation(.easeInOut)
            .onTapGesture {
                UIApplication.shared.windows
                    .first { $0.isKeyWindow }?
                    .endEditing(true)
            }
            .navigationBarTitle(Text(viewModel.appState.rawValue), displayMode: .inline)
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text(viewModel.actionSheetTitle), message: nil, buttons: actionSheetButtons())
        }
    }
    
    private func actionSheetButtons() -> [ActionSheet.Button] {
        var buttons = [ActionSheet.Button]()
        
        switch viewModel.appState {
        case .inactive:
            buttons += [
                .default(Text("Host Chat")) {
                    self.viewModel.startAdvertising()
                },
                .default(Text("Join Chat")) {
                    self.viewModel.startBrowsing()
                }
            ]
        default:
            buttons += [
                .default(Text("Disconnect")) {
                    self.viewModel.disconnect()
                }
            ]
        }
        
        buttons.append(.cancel())
        return buttons
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .environmentObject(ChatViewModel())
                .previewDevice("iPhone 11 Pro Max")
                .previewDisplayName("iPhone 11 Pro Max")
            
            ContentView()
                .environmentObject(ChatViewModel())
                .previewDevice("iPhone SE")
                .previewDisplayName("iPhone SE")
                .environment(\.colorScheme, .dark)
        }
    }
}
