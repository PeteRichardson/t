
import EventKit

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs === rhs || lhs.compare(rhs as Date) == .orderedSame
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs as Date) == .orderedAscending
}

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
}
