
import EventKit

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs === rhs || lhs.compare(rhs) == .OrderedSame
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs) == .OrderedAscending
}

extension NSDate: Comparable {
    public func dateWithoutTime() -> NSDate {
        let comps = NSCalendar.currentCalendar().components([.Year, .Month, .Day], fromDate: self)
        return NSCalendar.currentCalendar().dateFromComponents(comps)!
    }
}

extension EKReminder {    
    public var completedToday: Bool {
        return self.completed && self.completionDate!.dateWithoutTime() == NSDate().dateWithoutTime()
    }
}