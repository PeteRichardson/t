
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
    public override var description: String {
        let completed : String = self.completed ? "✔" : " "
        let hash = NSString(format:"%02X", self.hash & 0xFF)
        return "\(completed)  \(hash) \(self.title)"
    }
    
    public var completedToday: Bool {
        return self.completed && self.completionDate!.dateWithoutTime() == NSDate().dateWithoutTime()
    }
}