import Foundation

class SessionCounter: ObservableObject {
    @Published var count: Int = 0
    let goal = 4

    private let countKey = "pomodoroSessionCount"
    private let dateKey = "pomodoroSessionDate"

    init() {
        load()
    }

    func increment() {
        count += 1
        save()
    }

    // MARK: - Persistence

    private func load() {
        let savedDate = UserDefaults.standard.string(forKey: dateKey) ?? ""
        if savedDate == dateString() {
            count = UserDefaults.standard.integer(forKey: countKey)
        } else {
            count = 0
            save()
        }
    }

    private func save() {
        UserDefaults.standard.set(count, forKey: countKey)
        UserDefaults.standard.set(dateString(), forKey: dateKey)
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
