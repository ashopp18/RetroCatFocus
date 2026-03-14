//
//  Localization.swift
//  RetroCatFocus
//
//  Created by Ismael Martinez Mohamed on 12/3/26.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case spanish = "es"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    
    var id: String { rawValue }
    
    var localeIdentifier: String {
        switch self {
        case .system:
            return resolvedSystemLanguageCode()
        case .spanish:
            return "es"
        case .english:
            return "en"
        case .japanese:
            return "ja"
        case .korean:
            return "ko"
        }
    }
    
    var nativeDisplayName: String {
        switch self {
        case .system:
            return "System"
        case .spanish:
            return "Español"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        }
    }
}

private let supportedLanguageCodes = ["en", "es", "ja", "ko"]

func resolvedSystemLanguageCode() -> String {
    let preferred = Locale.preferredLanguages.first ?? "en"
    let code = Locale(identifier: preferred).language.languageCode?.identifier ?? "en"
    return supportedLanguageCodes.contains(code) ? code : "en"
}

func localized(_ key: String, languageCode: String) -> String {
    let resolvedCode = languageCode == AppLanguage.system.rawValue
        ? resolvedSystemLanguageCode()
        : languageCode
    
    guard
        let path = Bundle.main.path(forResource: resolvedCode, ofType: "lproj"),
        let bundle = Bundle(path: path)
    else {
        guard
            let fallbackPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
            let fallbackBundle = Bundle(path: fallbackPath)
        else {
            return key
        }
        
        return fallbackBundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    return bundle.localizedString(forKey: key, value: nil, table: nil)
}

func localizedFormat(_ key: String, languageCode: String, _ args: CVarArg...) -> String {
    let resolvedCode = languageCode == AppLanguage.system.rawValue
        ? resolvedSystemLanguageCode()
        : languageCode
    
    let format = localized(key, languageCode: resolvedCode)
    return String(format: format, locale: Locale(identifier: resolvedCode), arguments: args)
}
