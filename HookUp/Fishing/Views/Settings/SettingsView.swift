import SwiftUI
import StoreKit

/// App settings, reachable from the gear button in the navigation bar of every
/// main tab. Three self-contained actions: open the Terms link, prompt for an
/// App Store review, and request a fishing-advice call-back (a purely local
/// popup + confirmation — it does not place or route any actual call).
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    // TODO: swap for the real Terms of Service URL before release.
    private let termsURL = URL(string: "https://www.termsfeed.com/live/1249976c-e2ed-4820-969e-6d19773ea041")!

    @State private var showCallPopup = false
    @State private var showCallConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 12) {
                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "Terms of Service",
                            subtitle: "How you can use Catchbook",
                            tint: FishingTheme.lake
                        ) {
                            openURL(termsURL)
                        }

                        SettingsRow(
                            icon: "star.fill",
                            title: "Rate Us",
                            subtitle: "Enjoying the app? Leave a review",
                            tint: FishingTheme.lureGold
                        ) {
                            requestReview()
                        }

                        SettingsRow(
                            icon: "phone.bubble.fill",
                            title: "Request a Call",
                            subtitle: "Get advice from our fishing team",
                            tint: FishingTheme.lake
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) { showCallPopup = true }
                        }
                    }
                    .padding()
                }
                .fishingBackground()

                if showCallPopup {
                    callPopup
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Thanks!", isPresented: $showCallConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("We'll call you back soon. Our team will reach out to help with your fishing questions.")
            }
        }
    }

    /// Custom (non-system) popup explaining the call-back offer.
    private var callPopup: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismissPopup() }

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(FishingTheme.lake.opacity(0.15))
                        .frame(width: 76, height: 76)
                    Image(systemName: "phone.badge.waveform.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(FishingTheme.lake)
                }

                VStack(spacing: 8) {
                    Text("Request a Call")
                        .font(FishingTheme.displayFont(22))
                        .foregroundStyle(FishingTheme.deepWater)
                    Text("Book a free call with our team for help and advice on fishing spots, tackle and bait selection, techniques, and more.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    Button(action: bookCall) {
                        Text("Book a Call")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(FishingTheme.deepWater, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button("Not now") { dismissPopup() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }
            }
            .padding(24)
            .background(FishingTheme.foam, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(FishingTheme.lake.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
            .padding(32)
        }
    }

    private func dismissPopup() {
        withAnimation(.easeInOut(duration: 0.2)) { showCallPopup = false }
    }

    private func bookCall() {
        withAnimation(.easeInOut(duration: 0.2)) { showCallPopup = false }
        // Small delay so the popup dismissal animation finishes before the alert.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showCallConfirmation = true
        }
    }
}

/// A single tappable settings entry styled to match the fishing theme cards.
private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(FishingTheme.deepWater)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(FishingTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(FishingTheme.lake.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Adds the Settings gear button to a screen's navigation bar and hosts the
/// Settings sheet. Applied to every main tab so the entry point is consistent.
private struct SettingsToolbarModifier: ViewModifier {
    @State private var showSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .tint(FishingTheme.lake)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
    }
}

extension View {
    /// Adds the shared Settings gear button to a tab screen's navigation bar.
    func fishingSettingsToolbar() -> some View {
        modifier(SettingsToolbarModifier())
    }
}

#Preview {
    SettingsView()
}
