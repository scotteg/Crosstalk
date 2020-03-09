//
//  ContentView.swift
//  Crosstalk
//
//  Created by Scott Gardner on 2/26/20.
//  Copyright © 2020 Scott Gardner. All rights reserved.
//

import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject private var viewModel = ChatViewModel()
    @State private var showActionSheet = false
    
    private let formatter = DateFormatter(dateStyle: .short, timeStyle: .short)
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack {
                        ForEach(viewModel.messages) { message in
                            Text(self.caption(for: message))
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            HStack {
                                if message.isFromLocalUser {
                                    Spacer()
                                }
                                
                                Text(message.value)
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .padding()
                                    .background(message.isFromLocalUser ? Color.blue : Color.gray)
                                    .cornerRadius(20)
                                    .padding(.leading, message.isFromLocalUser ? 20 : 8)
                                    .padding(.trailing, message.isFromLocalUser ? 8 : 20)
                                    .padding(.vertical, 5)
                                
                                if message.isFromLocalUser == false {
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .navigationBarTitle(Text(viewModel.appState.rawValue), displayMode: .inline)
                
                HStack {
                    Button(action: {
                        self.showActionSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .padding(.horizontal, 8)
                    
                    TextField(viewModel.appState.notConnected ? "Inactive" : "Add message",
                              text: $viewModel.newMessageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.appState.notConnected)
                    
                    Button(action: {
                        self.viewModel.clear()
                    }) {
                        Image(systemName: "xmark.circle")
                    }
                    .disabled(viewModel.newMessageTextIsEmpty)
                    
                    Button(action: {
                        self.viewModel.send()
                    }) {
                        Image(systemName: "paperplane")
                    }
                    .disabled(viewModel.newMessageTextIsEmpty)
                        .padding(.horizontal, 8)
                }
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
    
    private func caption(for message: Message) -> String {
        (message.isFromLocalUser ? "" : "\(message.username) - ") + "\(message.timestamp)"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice("iPhone 11 Pro Max")
                .previewDisplayName("iPhone 11 Pro Max")
            
            ContentView()
                .previewDevice("iPhone SE")
                .previewDisplayName("iPhone SE")
                .environment(\.colorScheme, .dark)
        }
    }
}
