
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
     
     - Algorithm: compare date components (.year, .month, .day)
     
     - Returns: True if date components all match
                False if date components do not match or if reminder has no completion date
     */
    public var completedToday: Bool {
        guard let completionDate = completionDate else {
            return false
        }
        
        let completion = NSCalendar.current.dateComponents([.year, .month, .day], from: completionDate)
        let today      = NSCalendar.current.dateComponents([.year, .month, .day], from: Date())

        return completion == today
    }
}
