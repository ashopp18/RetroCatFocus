//
//  SettingsView.swift
//  RetroCatFocus
//
//  Created by Ismael Martinez Mohamed on 12/3/26.
//

import SwiftUI
import MessageUI

struct SettingsView: View {
    @Binding var weeklyPomodoros: Int
    @Binding var timeRemaining: Int
    @Binding var timerIsRunning: Bool
    @Binding var hasBeenInactiveForAWeek: Bool
    
    let pomodoroDuration: Int
    let clearWeeklyPomodoros: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = AppLanguage.system.rawValue
    
    @State private var showingMailComposer = false
    
    private let pixelFontName = "VCR OSD Mono"
    private let bgColor = Color(red: 0.95, green: 0.90, blue: 0.84)
    private let panelColor = Color(red: 0.98, green: 0.94, blue: 0.89)
    private let borderColor = Color(red: 0.23, green: 0.18, blue: 0.16)
    private let secondaryTextColor = Color(red: 0.38, green: 0.32, blue: 0.29)
    
    private let availableLanguages = AppLanguage.allCases
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgColor
                    .ignoresSafeArea()
                
                VStack(spacing: 18) {
                    settingsSection(title: localized("settings_section_language", languageCode: selectedLanguageCode)) {
                        VStack(spacing: 8) {
                            ForEach(availableLanguages) { language in
                                Button(action: {
                                    selectedLanguageCode = language.rawValue
                                }) {
                                    HStack {
                                        Text(languageRowTitle(language))
                                            .font(.custom(pixelFontName, size: 14))
                                        
                                        Spacer()
                                        
                                        if selectedLanguageCode == language.rawValue {
                                            Text("•")
                                                .font(.custom(pixelFontName, size: 18))
                                        }
                                    }
                                    .foregroundColor(borderColor)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedLanguageCode == language.rawValue ? bgColor : panelColor)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(borderColor.opacity(0.25), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    settingsSection(title: localized("settings_section_support", languageCode: selectedLanguageCode)) {
                        Button(action: {
                            if MFMailComposeViewController.canSendMail() {
                                showingMailComposer = true
                            } else {
                                openSupportEmailFallback()
                            }
                        }) {
                            HStack {
                                Text(localized("settings_send_email", languageCode: selectedLanguageCode))
                                    .font(.custom(pixelFontName, size: 14))
                                Spacer()
                                Image(systemName: "envelope.fill")
                            }
                            .foregroundColor(borderColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(bgColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(borderColor.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    settingsSection(title: localized("settings_section_development", languageCode: selectedLanguageCode)) {
                        Button(action: {
                            clearWeeklyPomodoros()
                        }) {
                            Text(localized("settings_clear_progress", languageCode: selectedLanguageCode))
                                .font(.custom(pixelFontName, size: 14))
                                .foregroundColor(borderColor)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(bgColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(borderColor.opacity(0.25), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle(localized("settings_title", languageCode: selectedLanguageCode))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("X")
                            .font(.custom(pixelFontName, size: 14))
                            .foregroundColor(borderColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showingMailComposer) {
                MailComposerView(
                    subject: localized("support_email_subject", languageCode: selectedLanguageCode),
                    body: localized("support_email_body", languageCode: selectedLanguageCode)
                )
            }
        }
    }
    
    @ViewBuilder
    func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom(pixelFontName, size: 12))
                .foregroundColor(secondaryTextColor)
            
            VStack(spacing: 8) {
                content()
            }
            .padding(14)
            .background(panelColor)
            .cornerRadius(16)
        }
    }
    
    func languageRowTitle(_ language: AppLanguage) -> String {
        switch language {
        case .system:
            return localized("language_system", languageCode: selectedLanguageCode)
        default:
            return language.nativeDisplayName
        }
    }
    
    func openSupportEmailFallback() {
        let email = "support@retrocatfocus.com"
        let subject = localized("support_email_subject", languageCode: selectedLanguageCode)
        let body = localized("support_email_body", languageCode: selectedLanguageCode)
        
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(email)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
            UIApplication.shared.open(url)
        }
    }
}

struct MailComposerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    let subject: String
    let body: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(["support@retrocatfocus.com"])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            dismiss()
        }
    }
}

#Preview {
    SettingsView(
        weeklyPomodoros: .constant(3),
        timeRemaining: .constant(1500),
        timerIsRunning: .constant(false),
        hasBeenInactiveForAWeek: .constant(false),
        pomodoroDuration: 1500,
        clearWeeklyPomodoros: {}
    )
}
