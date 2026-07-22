import SwiftUI
import SwiftData
import UIKit

struct FishingTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimerSession.startedAt, order: .reverse) private var pastSessions: [TimerSession]

    @State private var activeSession: TimerSession?
    @State private var intervalMinutes: Double = 10
    @State private var remainingSeconds: Int = 600
    @State private var timer: Timer?
    @State private var isRunning = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    countdownRing

                    if activeSession == nil {
                        Stepper("Interval: \(Int(intervalMinutes)) min", value: $intervalMinutes, in: 1...60, step: 1)
                            .onChange(of: intervalMinutes) { _, newValue in
                                remainingSeconds = Int(newValue * 60)
                            }
                    }

                    HStack(spacing: 16) {
                        if activeSession == nil {
                            Button(action: startSession) {
                                Label("Start", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(action: recast) {
                                Label("Recast", systemImage: "arrow.triangle.2.circlepath")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            Button(action: endSession) {
                                Label("Stop", systemImage: "stop.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if let activeSession {
                        SectionCard(title: "Current Session") {
                            HStack {
                                StatCard(title: "Recasts", value: "\(activeSession.recastCount)", systemImage: "arrow.triangle.2.circlepath")
                                StatCard(title: "Duration", value: formattedDuration(activeSession.durationSeconds), systemImage: "clock")
                            }
                        }
                    }

                    if !pastSessions.isEmpty {
                        SectionCard(title: "Session Log") {
                            let recentSessions = Array(pastSessions.prefix(20))
                            VStack(spacing: 10) {
                                ForEach(recentSessions) { session in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                                .font(.subheadline)
                                            Text("\(session.recastCount) recasts · \(formattedDuration(session.durationSeconds))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    if session.id != recentSessions.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .fishingBackground()
            .navigationTitle("Recast Timer")
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var countdownRing: some View {
        ZStack {
            Circle()
                .stroke(FishingTheme.sand, lineWidth: 14)
            Circle()
                .trim(from: 0, to: progressFraction)
                .stroke(
                    isRunning
                        ? AnyShapeStyle(LinearGradient(colors: [FishingTheme.lake, FishingTheme.lureGold], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(Color.gray),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: remainingSeconds)
            VStack {
                Text(timeString(remainingSeconds))
                    .font(FishingTheme.displayFont(44))
                    .foregroundStyle(FishingTheme.deepWater)
                    .monospacedDigit()
                Text(isRunning ? "until next cast" : "timer stopped")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 220, height: 220)
        .padding(.top, 12)
    }

    private var progressFraction: CGFloat {
        let total = max(1, Int(intervalMinutes * 60))
        return CGFloat(remainingSeconds) / CGFloat(total)
    }

    private func startSession() {
        let session = TimerSession(recastIntervalSeconds: Int(intervalMinutes * 60))
        modelContext.insert(session)
        activeSession = session
        remainingSeconds = Int(intervalMinutes * 60)
        isRunning = true
        scheduleTimer()
    }

    private func recast() {
        activeSession?.recastTimestamps.append(.now)
        remainingSeconds = Int(intervalMinutes * 60)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        try? modelContext.save()
    }

    private func endSession() {
        activeSession?.endedAt = .now
        try? modelContext.save()
        timer?.invalidate()
        timer = nil
        isRunning = false
        activeSession = nil
        remainingSeconds = Int(intervalMinutes * 60)
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard isRunning else { return }
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                remainingSeconds = Int(intervalMinutes * 60)
            }
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes >= 60 {
            return String(format: "%dh %02dm", minutes / 60, minutes % 60)
        }
        return "\(minutes) min"
    }
}
