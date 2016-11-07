
import EventKit

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs === rhs || lhs.compare(rhs as Date) == .orderedSame
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs as Date) == .orderedAscending
}

extension EKReminder {    
    public var completedToday: Bool {
		let calendar = NSCalendar.current

		let completionyear  = calendar.component(.year,  from: self.completionDate! as Date)
		let completionmonth = calendar.component(.month, from: self.completionDate! as Date)
		let completionday   = calendar.component(.day,   from: self.completionDate! as Date)

		let today  = NSDate()
		let year  = calendar.component(.hour, from: today as Date)
		let month = calendar.component(.minute, from: today as Date)
		let day   = calendar.component(.day, from: today as Date)

		return ((completionday == day) && (completionmonth == month) && (completionyear == year))
    }
}