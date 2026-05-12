import SwiftUI

@main
struct FTM150iOSApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var settings: AppSettings
    @StateObject private var viewModel: RadioViewModel

    init() {
        let settings = AppSettings()
        _settings = StateObject(wrappedValue: settings)
        _viewModel = StateObject(wrappedValue: RadioViewModel(settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel, settings: settings)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                viewModel.releaseAllHeldCommands()
                viewModel.stopTXAudio()
            }
        }
    }
}
