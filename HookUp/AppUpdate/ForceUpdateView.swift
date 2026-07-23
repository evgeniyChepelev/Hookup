import SwiftUI
import UIKit

/// Native, self-contained "please update" screen.
///
/// It shows fixed, in-app copy and a single button that opens this app's
/// App Store page. It deliberately loads no remote web content — the only
/// two outcomes of the update gate are "run the app" or "show this screen".
struct ForceUpdateView: View {

    private var appStoreURL: URL? {
        URL(string: "itms-apps://itunes.apple.com/app/id\(RemoteConfig.appStoreId)")
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 76))
                .foregroundStyle(FishingTheme.lake)

            VStack(spacing: 12) {
                Text("Доступно обновление")
                    .font(FishingTheme.displayFont(28))
                    .foregroundStyle(FishingTheme.deepWater)
                    .multilineTextAlignment(.center)

                Text("Вышла новая версия приложения. Обновитесь в App Store, чтобы продолжить пользоваться всеми функциями.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                if let appStoreURL {
                    UIApplication.shared.open(appStoreURL)
                }
            } label: {
                Text("Обновить в App Store")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(FishingTheme.lake)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fishingBackground()
    }
}

#Preview {
    ForceUpdateView()
}
