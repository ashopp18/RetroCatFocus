//
//  ContentView.swift
//  RetroCatFocus
//
//  Created by Ismael Martinez Mohamed on 7/3/26.
//


import SwiftUI
import Combine
import UserNotifications
import UIKit

struct ContentView: View {
    private let weeklyPomodorosKey = "weeklyPomodoros"
    private let lastActiveDateKey = "lastActiveDate"
    private let lastPomodoroDateKey = "lastPomodoroDate"
    private let selectedPomodoroMinutesKey = "selectedPomodoroMinutes"
    private let sadCatNotificationIdentifier = "sadCatReminder"
    private let inactivityInterval: TimeInterval = 7 * 24 * 60 * 60
    //private let inactivityInterval: TimeInterval = 30
    private let availableDurations = [10, 25, 50]
    
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = AppLanguage.system.rawValue
    
    @State private var selectedPomodoroMinutes: Int = 25
    @State private var timeRemaining: Int = 25 * 60
    @State private var timerIsRunning: Bool = false
    @State private var timerEndDate: Date? = nil
    
    @State private var weeklyPomodoros: Int = 0
    @State private var currentCatFrame: Int = 0
    @State private var hasBeenInactiveForAWeek: Bool = false
    @State private var showingSettings: Bool = false
    
    @Environment(\.scenePhase) private var scenePhase
    
    let inactivityCheckTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let catAnimationTimer = Timer.publish(every: 0.7, on: .main, in: .common).autoconnect()
    
    private let bgColor = Color(red: 0.95, green: 0.90, blue: 0.84)
    private let panelColor = Color(red: 0.98, green: 0.94, blue: 0.89)
    private let borderColor = Color(red: 0.23, green: 0.18, blue: 0.16)
    private let secondaryTextColor = Color(red: 0.38, green: 0.32, blue: 0.29)
    private let pixelFontName = "VCR OSD Mono"
    
    var body: some View {
        ZStack {
            bgColor
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(borderColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
                
                Text(localized("app_title", languageCode: selectedLanguageCode))
                    .font(.custom(pixelFontName, size: 14))
                    .foregroundColor(borderColor)
                    .tracking(1.5)
                
                VStack(spacing: 18) {
                    Image(currentCatFrames[currentCatFrame])
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 170, height: 170)
                    
                    Text(formattedTime)
                        .font(.custom(pixelFontName, size: 42))
                        .foregroundColor(borderColor)
                    
                    VStack(spacing: 8) {
                        Text(localized("duration_label", languageCode: selectedLanguageCode))
                            .font(.custom(pixelFontName, size: 12))
                            .foregroundColor(secondaryTextColor)
                        
                        HStack(spacing: 8) {
                            ForEach(availableDurations, id: \.self) { minutes in
                                Button(action: {
                                    selectedPomodoroMinutes = minutes
                                    saveSelectedPomodoroMinutes()
                                    resetTimerForSelectedDuration()
                                }) {
                                    Text("\(minutes)M")
                                        .font(.custom(pixelFontName, size: 14))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selectedPomodoroMinutes == minutes ? borderColor : bgColor)
                                        .foregroundColor(selectedPomodoroMinutes == minutes ? panelColor : borderColor)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(borderColor.opacity(0.5), lineWidth: 1)
                                        )
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    HStack(spacing: 14) {
                        Button(action: {
                            handleStartPauseTapped()
                        }) {
                            Text(localized(timerIsRunning ? "button_pause" : "button_start", languageCode: selectedLanguageCode))
                                .font(.custom(pixelFontName, size: 16))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(borderColor)
                                .foregroundColor(panelColor)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            resetTimer()
                        }) {
                            Text(localized("button_reset", languageCode: selectedLanguageCode))
                                .font(.custom(pixelFontName, size: 16))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(bgColor)
                                .foregroundColor(borderColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(borderColor.opacity(0.7), lineWidth: 1.5)
                                )
                        }
                    }
                    
                    VStack(spacing: 12) {
                        infoRow(
                            title: localized("weekly_title", languageCode: selectedLanguageCode),
                            value: localizedFormat("weekly_value_format", languageCode: selectedLanguageCode, weeklyPomodoros)
                        )
                        
                        infoRow(
                            title: localized("mood_title", languageCode: selectedLanguageCode),
                            value: catMoodText
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(maxWidth: 340)
                .background(panelColor)
                .cornerRadius(18)
                
                Spacer(minLength: 12)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                weeklyPomodoros: $weeklyPomodoros,
                timeRemaining: $timeRemaining,
                timerIsRunning: $timerIsRunning,
                hasBeenInactiveForAWeek: $hasBeenInactiveForAWeek,
                pomodoroDuration: pomodoroDuration,
                clearWeeklyPomodoros: clearWeeklyPomodoros
            )
        }
        .onAppear {
            requestNotificationPermission()
            loadSelectedPomodoroMinutes()
            loadWeeklyData()
            checkForNewWeek()
            checkInactivityStatus()
            updateTimerFromEndDate()
            updateIdleTimerState()
        }
        .onReceive(timer) { _ in
            guard timerIsRunning else { return }
            updateTimerFromEndDate()
        }
        .onReceive(catAnimationTimer) { _ in
            currentCatFrame = (currentCatFrame + 1) % currentCatFrames.count
        }
        .onReceive(inactivityCheckTimer) { _ in
            checkInactivityStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkInactivityStatus()
                updateTimerFromEndDate()
            }
        }
        .onChange(of: currentCatMood) { _, _ in
            currentCatFrame = 0
        }
    }
    
    @ViewBuilder
    func infoRow(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.custom(pixelFontName, size: 11))
                .foregroundColor(secondaryTextColor)
                .tracking(1)
            
            Text(value)
                .font(.custom(pixelFontName, size: 14))
                .foregroundColor(borderColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(bgColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor.opacity(0.25), lineWidth: 1)
                )
        }
    }
    
    var pomodoroDuration: Int {
        selectedPomodoroMinutes * 60
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var currentCatMood: String {
        if hasBeenInactiveForAWeek && !timerIsRunning {
            return "sad"
        }
        
        switch weeklyPomodoros {
        case 0...2:
            return "normal"
        case 3...5:
            return "happy"
        default:
            return "veryHappy"
        }
    }
    
    var currentCatFrames: [String] {
        switch currentCatMood {
        case "sad":
            return ["sad_cat1", "sad_cat2", "sad_cat3", "sad_cat4"]
        case "happy":
            return ["happy_cat1", "happy_cat2", "happy_cat3", "happy_cat4"]
        case "veryHappy":
            return ["very_happy_cat1", "very_happy_cat2", "very_happy_cat3", "very_happy_cat4"]
        default:
            return ["normal_cat1", "normal_cat2", "normal_cat3", "normal_cat4"]
        }
    }
    
    var catMoodText: String {
        switch currentCatMood {
        case "sad":
            return localized("mood_sad", languageCode: selectedLanguageCode)
        case "happy":
            return localized("mood_happy", languageCode: selectedLanguageCode)
        case "veryHappy":
            return localized("mood_very_happy", languageCode: selectedLanguageCode)
        default:
            return localized("mood_normal", languageCode: selectedLanguageCode)
        }
    }
    
    func handleStartPauseTapped() {
        if timerIsRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    func startTimer() {
        if timeRemaining <= 0 {
            timeRemaining = pomodoroDuration
        }
        
        timerEndDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
        timerIsRunning = true
        updateIdleTimerState()
    }
    
    func pauseTimer() {
        updateTimerFromEndDate()
        timerEndDate = nil
        timerIsRunning = false
        updateIdleTimerState()
    }
    
    func resetTimer() {
        timeRemaining = pomodoroDuration
        timerIsRunning = false
        timerEndDate = nil
        updateIdleTimerState()
    }
    
    func resetTimerForSelectedDuration() {
        timeRemaining = pomodoroDuration
        timerIsRunning = false
        timerEndDate = nil
        updateIdleTimerState()
    }
    
    func updateTimerFromEndDate() {
        guard timerIsRunning, let timerEndDate else { return }
        
        let remaining = Int(ceil(timerEndDate.timeIntervalSinceNow))
        
        if remaining > 0 {
            timeRemaining = remaining
        } else {
            completePomodoro()
        }
    }
    
    func updateIdleTimerState() {
        UIApplication.shared.isIdleTimerDisabled = timerIsRunning
    }
    
    func completePomodoro() {
        weeklyPomodoros += 1
        timerIsRunning = false
        timerEndDate = nil
        timeRemaining = pomodoroDuration
        updateIdleTimerState()
        
        let now = Date()
        saveWeeklyData(lastPomodoroDate: now)
        hasBeenInactiveForAWeek = false
        scheduleSadCatNotification(from: now)
    }
    
    func saveWeeklyData(lastPomodoroDate: Date? = nil) {
        UserDefaults.standard.set(weeklyPomodoros, forKey: weeklyPomodorosKey)
        UserDefaults.standard.set(Date(), forKey: lastActiveDateKey)
        
        if let lastPomodoroDate {
            UserDefaults.standard.set(lastPomodoroDate, forKey: lastPomodoroDateKey)
        }
    }
    
    func loadWeeklyData() {
        weeklyPomodoros = UserDefaults.standard.integer(forKey: weeklyPomodorosKey)
    }
    
    func checkForNewWeek() {
        let calendar = Calendar.current
        let now = Date()
        
        guard let lastActiveDate = UserDefaults.standard.object(forKey: lastActiveDateKey) as? Date else {
            UserDefaults.standard.set(now, forKey: lastActiveDateKey)
            return
        }
        
        if !calendar.isDate(lastActiveDate, equalTo: now, toGranularity: .weekOfYear) {
            weeklyPomodoros = 0
            saveWeeklyData()
        }
    }
    
    func checkInactivityStatus() {
        guard let lastPomodoroDate = UserDefaults.standard.object(forKey: lastPomodoroDateKey) as? Date else {
            hasBeenInactiveForAWeek = false
            return
        }
        
        hasBeenInactiveForAWeek = Date().timeIntervalSince(lastPomodoroDate) >= inactivityInterval
    }
    
    func clearWeeklyPomodoros() {
        weeklyPomodoros = 0
        hasBeenInactiveForAWeek = false
        timeRemaining = pomodoroDuration
        timerIsRunning = false
        timerEndDate = nil
        updateIdleTimerState()
        
        UserDefaults.standard.removeObject(forKey: weeklyPomodorosKey)
        UserDefaults.standard.removeObject(forKey: lastActiveDateKey)
        UserDefaults.standard.removeObject(forKey: lastPomodoroDateKey)
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [sadCatNotificationIdentifier]
        )
    }
    
    func saveSelectedPomodoroMinutes() {
        UserDefaults.standard.set(selectedPomodoroMinutes, forKey: selectedPomodoroMinutesKey)
    }
    
    func loadSelectedPomodoroMinutes() {
        let savedValue = UserDefaults.standard.integer(forKey: selectedPomodoroMinutesKey)
        
        if availableDurations.contains(savedValue) {
            selectedPomodoroMinutes = savedValue
        } else {
            selectedPomodoroMinutes = 25
        }
        
        timeRemaining = pomodoroDuration
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
        }
    }
    
    func scheduleSadCatNotification(from date: Date) {
        let center = UNUserNotificationCenter.current()
        
        center.removePendingNotificationRequests(withIdentifiers: [sadCatNotificationIdentifier])
        
        let content = UNMutableNotificationContent()
        content.title = localized("notification_sad_title", languageCode: selectedLanguageCode)
        content.body = localized("notification_sad_body", languageCode: selectedLanguageCode)
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(inactivityInterval, 5),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: sadCatNotificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
}

#Preview {
    ContentView()
}
