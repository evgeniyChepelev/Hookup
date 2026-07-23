import SwiftUI

/// One step of the first-launch walkthrough that introduces Catchbook's core features.
private struct OnboardingPage {
    let symbol: String
    let accentSymbols: [String]
    let title: String
    let message: String
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        symbol: "book.closed.fill",
        accentSymbols: ["fish.fill", "pencil"],
        title: "Log every catch",
        message: "Keep a trip journal with species, length, weight, bait, and conditions — all in one place."
    ),
    OnboardingPage(
        symbol: "camera.viewfinder",
        accentSymbols: ["ruler.fill", "checkmark.circle.fill"],
        title: "Measure with your camera",
        message: "Snap a photo next to your catch and Catchbook estimates its length and weight for you."
    ),
    OnboardingPage(
        symbol: "map.fill",
        accentSymbols: ["mappin.circle.fill", "star.fill"],
        title: "Discover the best spots",
        message: "Pin your favorite fishing spots, rate them, and see depth, bottom type, and weather at a glance."
    ),
    OnboardingPage(
        symbol: "trophy.fill",
        accentSymbols: ["chart.bar.fill", "timer"],
        title: "Track stats & personal bests",
        message: "Watch your biggest catches, session timers, and achievements add up with every trip."
    ),
]

/// Layered SF Symbols composition standing in for hand-drawn artwork on each
/// onboarding page — keeps the module dependency-free while still feeling illustrated.
private struct OnboardingIllustration: View {
    let page: OnboardingPage

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [FishingTheme.lake.opacity(0.35), FishingTheme.lake.opacity(0.04)],
                        center: .center, startRadius: 10, endRadius: 140
                    )
                )
                .frame(width: 240, height: 240)

            Circle()
                .stroke(FishingTheme.lureGold.opacity(0.4), lineWidth: 2)
                .frame(width: 190, height: 190)

            Image(systemName: page.symbol)
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(FishingTheme.deepWater)

            ForEach(Array(page.accentSymbols.enumerated()), id: \.offset) { index, symbolName in
                Image(systemName: symbolName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(FishingTheme.lureGold)
                    .padding(10)
                    .background(Circle().fill(FishingTheme.foam))
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    .offset(accentOffset(for: index))
            }
        }
        .frame(height: 260)
    }

    private func accentOffset(for index: Int) -> CGSize {
        index == 0 ? CGSize(width: -88, height: -72) : CGSize(width: 92, height: 64)
    }
}

/// Four-screen first-launch walkthrough introducing Catchbook's journal, camera
/// measurement, spot map, and stats features. Shown once via `hasCompletedOnboarding`.
struct FishingOnboardingView: View {
    let onFinish: () -> Void

    @State private var pageIndex = 0
    private let pages = onboardingPages

    var body: some View {
        ZStack {
            FishingTheme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") { onFinish() }
                        .foregroundStyle(.secondary)
                        .opacity(pageIndex == pages.count - 1 ? 0 : 1)
                        .disabled(pageIndex == pages.count - 1)
                }
                .padding(.horizontal)
                .frame(height: 32)

                TabView(selection: $pageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 28) {
                            Spacer(minLength: 12)
                            OnboardingIllustration(page: page)
                            VStack(spacing: 12) {
                                Text(page.title)
                                    .font(FishingTheme.displayFont(28))
                                    .foregroundStyle(FishingTheme.deepWater)
                                    .multilineTextAlignment(.center)
                                Text(page.message)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 28)
                            }
                            Spacer(minLength: 12)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator

                Button(action: advance) {
                    Text(pageIndex == pages.count - 1 ? "Get started" : "Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(FishingTheme.deepWater, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == pageIndex ? FishingTheme.lureGold : FishingTheme.lake.opacity(0.25))
                    .frame(width: index == pageIndex ? 22 : 8, height: 8)
                    .animation(.easeInOut, value: pageIndex)
            }
        }
        .padding(.top, 4)
    }

    private func advance() {
        if pageIndex == pages.count - 1 {
            onFinish()
        } else {
            withAnimation { pageIndex += 1 }
        }
    }
}

#Preview {
    FishingOnboardingView(onFinish: {})
}
