
import EventKit

class ReminderCache {
    var uiItems    = [String: EKReminder]()
    var nuiItems   = [String: EKReminder]()
    var uniItems   = [String: EKReminder]()
    var nuniItems  = [String: EKReminder]()
    var reminders: [EKReminder]!
    
    var eventStore: EKEventStore

    init() {
	    self.eventStore = EKEventStore()
	    eventStore.requestAccessToEntityType(EKEntityType.Reminder, completion: {
	        (granted, error) in
	        if (granted) && (error == nil) {
	            //print("Access granted!")
	        }
	    })
    
        self.reminders = [EKReminder]()
        self.loadItems()
    }
    
    func loadItems() {
        var fetched: Bool = false
        let cal = self.eventStore.defaultCalendarForNewReminders()
        
        let predicate = self.eventStore.predicateForRemindersInCalendars([cal])
        
        self.eventStore.fetchRemindersMatchingPredicate(predicate) { foundReminders in
            
            self.reminders = foundReminders
            
            for reminder in self.reminders as [EKReminder]! {
                if (reminder.completed) && (!reminder.completedToday) {
                    continue
                }
                let key:String = NSString(format:"%02X", reminder.hash & 0xFF) as String
                switch (reminder.priority) {
                case (1):
                    self.uiItems[key] = reminder
                case (5):
                    self.nuiItems[key] = reminder
                case (9):
                    self.uniItems[key] = reminder
                case (0):
                    self.nuniItems[key] = reminder
                default:
                    print("Unexpected priority");
                }
            }
            fetched = true
        }
        
        
        let interval : UInt32 = 2500    // ms  (passed to usleep())
        let timeout : UInt32 = 11050000    // ms
        var counter : UInt32 = 0
        while !fetched && (counter < timeout) {
            counter += interval
            usleep(interval)
        }
        if !fetched {
            print("Error:  unable to load calendar items")
        }
    }
    
    func add_reminder(args:[String], priority:Int) {
        let reminder = EKReminder(eventStore: self.eventStore)
        reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
        
        reminder.title = args.joinWithSeparator(" ")
        reminder.priority = priority
        if reminder.title.isEmpty {
            print("# Error: Can't add empty reminder")
            return
        }
        
        do {
            try self.eventStore.saveReminder(reminder, commit:true);
            let key:String = NSString(format:"%02X", reminder.hash & 0xFF) as String
            switch (reminder.priority) {
            case (1):
                self.uiItems[key] = reminder
            case (5):
                self.nuiItems[key] = reminder
            case (9):
                self.uniItems[key] = reminder
            case (0):
                self.nuniItems[key] = reminder
            default:
                print("Unexpected priority");
            }
            print("Added reminder: \(reminder.title)")
        } catch {
            print("Failed to add reminder!")
        }
    }
    
    func delete_reminder(args:[String]) throws {
        for arg in args {
            let hash = arg.uppercaseString
            let iItems : Bool = (self.uiItems[hash] == nil) && (self.nuiItems[hash] == nil)
            let uItems : Bool = (self.uniItems[hash] == nil) && (self.nuniItems[hash] == nil)
            if  iItems && uItems {
                print("Error: no reminder with id \(hash)")
                continue
            }
            if let reminder : EKReminder = self.uiItems[hash] {
                let title:String = reminder.title
                try self.eventStore.removeReminder(reminder, commit:true)
                self.uiItems[hash] = nil
                print("Deleted ui reminder: \(title)")
            }
            if let reminder : EKReminder = self.nuiItems[hash] {
                let title:String = reminder.title
                try self.eventStore.removeReminder(reminder, commit:true);
                self.nuiItems[hash] = nil
                print("Deleted nui reminder: \(title)")
            }
            if let reminder : EKReminder = self.uniItems[hash] {
                let title:String = reminder.title
                try self.eventStore.removeReminder(reminder, commit:true);
                self.uniItems[hash] = nil
                print("Deleted uni reminder: \(title)")
            }
            if let reminder : EKReminder = self.nuniItems[hash] {
                let title:String = reminder.title
                try self.eventStore.removeReminder(reminder, commit:true);
                self.nuniItems[hash] = nil
                print("Deleted nuni reminder: \(title)")
            }
        }
        
    }
    
    func complete_reminder(args:[String]) throws {
        for arg in args {
            let hash = arg.uppercaseString
            let iItems : Bool = (self.uiItems[hash] == nil) && (self.nuiItems[hash] == nil)
            let uItems : Bool = (self.uniItems[hash] == nil) && (self.nuniItems[hash] == nil)
            if  iItems && uItems {
                print("Error: no reminder with id \(hash)")
                continue
            }
            if let reminder : EKReminder = self.uiItems[hash] {
                reminder.completed = true
                try self.eventStore.saveReminder(reminder, commit:true);
                print("Completed reminder: \(reminder.title)")
            }
            if let reminder : EKReminder = self.nuiItems[hash] {
                reminder.completed = true
                try self.eventStore.saveReminder(reminder, commit:true);
                print("Completed reminder: \(reminder.title)")
            }
            if let reminder : EKReminder = self.uniItems[hash] {
                reminder.completed = true
                try self.eventStore.saveReminder(reminder, commit:true);
                print("Completed reminder: \(reminder.title)")
            }
            if let reminder : EKReminder = self.nuniItems[hash] {
                reminder.completed = true
                try self.eventStore.saveReminder(reminder, commit:true);
                print("Completed reminder: \(reminder.title)")
            }
        }
    }
    
    func list_reminders(reminderlist: [String: EKReminder]) {
        if reminderlist.count > 0 {
            let sortedReminders = reminderlist.values.sort() { (r1, r2) in
                return r2.completed
            }
            for reminder in sortedReminders as [EKReminder] {
                if (!reminder.completed) || (reminder.completedToday) {
                    print(reminder)
                }
            }
        }
    }
    
    func list_reminders_side_by_side(list1: [String: EKReminder], list2: [String: EKReminder], width1: Int, width2: Int) {
        var rows = list1.count
        if list2.count > list1.count {
            rows = list2.count
        }
        var sortedList1 = list1.values.sort() { (r1, r2) in
            return r2.completed
        }
        var sortedList2 = list2.values.sort() { (r1, r2) in
            return r2.completed
        }
        
        for x in 0..<rows {
            var left: String = "                                        "
            if x < sortedList1.count {
                left = sortedList1[x].description + left
            }
            left = left.substringToIndex(left.startIndex.advancedBy(width1))
            var right: String = "                                        "
            if x < sortedList2.count {
                right = sortedList2[x].description + right
            }
            right = right.substringToIndex(right.startIndex.advancedBy(width1))
            print("| \(left) | \(right) |")
        }
    }
    
    func list_reminders2() {
        var width_urgent : Int = 0
        var width_noturgent : Int = 0
        var length_important : Int = 0
        var length_notimportant : Int = 0
        for reminder in self.uiItems.values {
            if reminder.priority <= 5 {
                length_important += 1
            } else {
                length_notimportant += 1
            }
            if ((reminder.priority == 1) || (reminder.priority == 9)) {
                if (reminder.description.characters.count > width_urgent) {
                    width_urgent = reminder.description.characters.count
                }
            }
            if ((reminder.priority == 0) || (reminder.priority == 5)) {
                if reminder.description.characters.count > width_noturgent {
                    width_noturgent = reminder.description.characters.count
                }
            }
            //print(reminder)
        }
        print(width_urgent)
        print(width_noturgent)
        print(length_important)
        print(length_notimportant)
    }
}
