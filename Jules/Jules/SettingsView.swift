//
//  SettingsView.swift
//  Jules
//
//  Created by Dion Almaer on 10/4/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.11, green: 0.11, blue: 0.15)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Jules API Key")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)

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
                        .foregroundColor(.white.opacity(0.6))
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    Spacer()

                    HStack {
                        Spacer()
                        Button(action: updateAPIKey) {
                            Text("Update API Key")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
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
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("API Key", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // Load existing API key if available
                if let existingKey = KeychainManager.shared.getAPIKey() {
                    apiKey = existingKey
                }
            }
        }
    }

    private func updateAPIKey() {
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
    SettingsView()
}
