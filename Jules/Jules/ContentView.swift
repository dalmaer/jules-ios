//
//  ContentView.swift
//  Jules
//
//  Created by Dion Almaer on 10/4/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showAPIKeyPrompt = false

    var body: some View {
        HomeView()
            .onAppear {
                // Check if API key exists on first launch
                if !KeychainManager.shared.hasAPIKey() {
                    showAPIKeyPrompt = true
                }
            }
            .sheet(isPresented: $showAPIKeyPrompt) {
                FirstLaunchAPIKeyView(isPresented: $showAPIKeyPrompt)
            }
    }
}

struct FirstLaunchAPIKeyView: View {
    @Binding var isPresented: Bool
    @State private var apiKey: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.11, green: 0.11, blue: 0.15)
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    VStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)

                        Text("Welcome to Jules")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("To get started, please enter your Jules API key")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Jules API Key")
                            .font(.headline)
                            .foregroundColor(.white)

                        TextField("Enter your Jules API key", text: $apiKey)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                                    )
                            )
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button(action: saveAPIKey) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.purple, Color.blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .padding(.horizontal)
                    .disabled(apiKey.isEmpty)
                    .opacity(apiKey.isEmpty ? 0.5 : 1.0)
                }
                .padding()
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
            .alert("API Key", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if alertMessage.contains("success") {
                        isPresented = false
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func saveAPIKey() {
        guard !apiKey.isEmpty else {
            alertMessage = "Please enter an API key"
            showAlert = true
            return
        }

        if KeychainManager.shared.saveAPIKey(apiKey) {
            alertMessage = "API key saved successfully!"
            showAlert = true
        } else {
            alertMessage = "Failed to save API key"
            showAlert = true
        }
    }
}

#Preview {
    ContentView()
}
