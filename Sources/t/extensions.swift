
import EventKit

extension EKReminder {
    
    /**
     Returns whether the reminder was completed today
     */
    public var completedToday: Bool {
        guard let completionDate = completionDate else {
            return false
        }
        
        return NSCalendar.current.isDateInToday(completionDate)
    }
    
    /**
     Convenient human-readable/typable key
     First three chars of String repr of hash
     */
    public var key: String {
        return String(calendarItemIdentifier.prefix(3))
    }
}
