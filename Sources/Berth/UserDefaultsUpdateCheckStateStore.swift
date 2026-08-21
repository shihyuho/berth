import BerthCore
import Foundation

final class UserDefaultsUpdateCheckStateStore: UpdateCheckStateStore {
    private static let stateKey = "UpdateCheckState"

    private let defaults: UserDefaults
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> UpdateCheckState {
        guard let data = defaults.data(forKey: Self.stateKey),
              let state = try? decoder.decode(UpdateCheckState.self, from: data) else {
            return UpdateCheckState()
        }
        return state
    }

    func save(_ state: UpdateCheckState) {
        guard let data = try? encoder.encode(state) else { return }
        defaults.set(data, forKey: Self.stateKey)
    }
}
