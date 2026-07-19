
/// The 10 priority levels used by Reminders (mirrors `EKReminder.priority`,
/// 0-9), repurposed here to select an Eisenhower quadrant and the sort
/// order within it. This is the single source of truth for that mapping;
/// previously it was hand-duplicated across `ReminderCache`,
/// `EisenhowerConsoleView`, and `main.swift`.
enum Priority: Int, CaseIterable {
    case uih  = 1   // urgent,     important (high)
    case ui   = 2   // urgent,     important (normal)
    case uil  = 3   // urgent,     important (low)
    case nuih = 4   // not urgent, important (high)
    case nui  = 5   // not urgent, important (normal)
    case nuil = 6   // not urgent, important (low)
    case unih = 7   // urgent,     not important (high)
    case uni  = 8   // urgent,     not important (normal)
    case unil = 9   // urgent,     not important (low)
    case nuni = 0   // not urgent, not important

    enum Quadrant {
        case urgentImportant        // top-left:     "DO"
        case notUrgentImportant     // top-right:    "PLAN"
        case urgentNotImportant     // bottom-left:  "DELEGATE"
        case notUrgentNotImportant  // bottom-right: "ELIMINATE"
    }

    var quadrant: Quadrant {
        switch self {
        case .uih, .ui, .uil:    return .urgentImportant
        case .nuih, .nui, .nuil: return .notUrgentImportant
        case .unih, .uni, .unil: return .urgentNotImportant
        case .nuni:               return .notUrgentNotImportant
        }
    }

    /// Accepts either the case name ("ui", "nuih", ...) or the equivalent digit ("2", "4", ...).
    init?(name: String) {
        if let byName = Priority.allCases.first(where: { "\($0)" == name }) {
            self = byName
        } else if let byNumber = Int(name), let byRaw = Priority(rawValue: byNumber) {
            self = byRaw
        } else {
            return nil
        }
    }
}
