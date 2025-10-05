//
//  JulesApp.swift
//  Jules
//
//  Created by Dion Almaer on 10/4/25.
//

import SwiftUI

@main
struct JulesApp: App {
    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
