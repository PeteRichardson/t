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


do {
    var eventStore : EKEventStore = EKEventStore()
    eventStore.requestAccessToEntityType(EKEntityType.Reminder, completion: {
        (granted, error) in
        if (granted) && (error == nil) {
            //print("Access granted!")
        }
    })
    
    var remCache = ReminderCache(eventStore: eventStore)
    
    var args = Process.arguments
    args.removeAtIndex(0)
    if args.count > 0 {
        switch (args[0]).lowercaseString {
        case "c", "-c":
            args.removeAtIndex(0)
            try remCache.complete_reminder(args)
        case "d", "-d":
            args.removeAtIndex(0)
            try remCache.delete_reminder(args)
        case "h", "ui":
            args.removeAtIndex(0)
            remCache.add_reminder(args, priority: 1)
        case "m", "nui":
            args.removeAtIndex(0)
            remCache.add_reminder(args, priority: 5)
        case "l", "uni":
            args.removeAtIndex(0)
            remCache.add_reminder(args, priority: 9)
        case "nuni":
            args.removeAtIndex(0)
            remCache.add_reminder(args, priority: 0)
        default:
            remCache.add_reminder(args, priority: 0)
        }
    }
    print("---------------------------------------------------------------------------------------")
    remCache.list_reminders_side_by_side(remCache.uiItems, list2:remCache.nuiItems, width1:40, width2:40)
    print("---------------------------------------------------------------------------------------")
    remCache.list_reminders_side_by_side(remCache.uniItems, list2:remCache.nuniItems, width1:40, width2:40)
    print("---------------------------------------------------------------------------------------")
} catch {
    print("Something is wrong")
}