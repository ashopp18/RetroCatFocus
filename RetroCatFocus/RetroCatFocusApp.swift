//
//  RetroCatFocusApp.swift
//  RetroCatFocus
//
//  Created by Ismael Martinez Mohamed on 7/3/26.
//

import SwiftUI

@main
struct RetroCatFocusApp: App {
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = AppLanguage.system.rawValue
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(
                    \.locale,
                    Locale(
                        identifier: selectedLanguageCode == AppLanguage.system.rawValue
                        ? resolvedSystemLanguageCode()
                        : (AppLanguage(rawValue: selectedLanguageCode)?.localeIdentifier ?? "en")
                    )
                )
        }
    }
}
