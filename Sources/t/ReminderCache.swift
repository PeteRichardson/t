
import EventKit

class ReminderCache {
    var uiItems: [String: EKReminder] {
        get {
            var result = [String: EKReminder]()
            for (hash, reminder) in self.reminders {
                if [1, 2, 3].contains(where: { $0 == reminder.priority }) {
                    result[hash] = reminder
                }
            }
            return result
        }
    }

    var nuiItems: [String: EKReminder] {
        get {
            var result = [String: EKReminder]()
            for (hash, reminder) in self.reminders {
                if [4, 5, 6].contains(where: { $0 == reminder.priority }) {
                    result[hash] = reminder
                }
            }
            return result
        }
    }
    var uniItems: [String: EKReminder] {
        get {
            var result = [String: EKReminder]()
            for (hash, reminder) in self.reminders {
                if [7, 8, 9].contains(where: { $0 == reminder.priority }) {
                    result[hash] = reminder
                }
            }
            return result
        }
    }
    var nuniItems: [String: EKReminder] {
        get {
            var result = [String: EKReminder]()
            for (hash, reminder) in self.reminders {
                if reminder.priority == 0 {
                    result[hash] = reminder
                }
            }
            return result
        }
    }
    var leftMaxWidth:Int
    var rightMaxWidth:Int
    var reminders = [String: EKReminder]()
    
    var eventStore: EKEventStore

    init() {
	    self.eventStore = EKEventStore()
	    eventStore.requestAccess(to: EKEntityType.reminder, completion: {
	        (granted, error) in
	        if (granted) && (error == nil) {
	            //print("Access granted!")
	        }
	    })
        self.leftMaxWidth = 0
        self.rightMaxWidth = 0
        self.loadItems()
    }
    
    func loadItems() {
        self.leftMaxWidth = 0
        self.rightMaxWidth = 0
        var fetched: Bool = false
        let cal = self.eventStore.defaultCalendarForNewReminders()
        
        let predicate = self.eventStore.predicateForReminders(in: [cal!])
        
        self.eventStore.fetchReminders(matching: predicate) { foundReminders in
            
            for reminder in foundReminders! {
                
                if (reminder.isCompleted) && (!reminder.completedToday) {
                    continue
                }
                let key:String = NSString(format:"%03X", reminder.hash & 0xFFF) as String
                self.reminders[key] = reminder
                //print("len(\(reminder.title) = \(reminder.title.count)")
                switch (reminder.priority) {
	                case 1,2,3,7,8,9:
                        if reminder.title.count > self.leftMaxWidth {
                            self.leftMaxWidth = reminder.title.count
                        }
	                case 0,4,5,6:
                        if reminder.title.count > self.rightMaxWidth {
                            self.rightMaxWidth = reminder.title.count
                        }
	                default:
	                    print("Unexpected priority");
                }
            }
            self.leftMaxWidth += 13
            self.rightMaxWidth += 13
            //print("after +13: leftMaxWidth = \(self.leftMaxWidth)")
            //print("after +13:  rightMaxWidth = \(self.rightMaxWidth)")
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
        
        reminder.title = args.joined(separator: " ")
        reminder.priority = priority
        if reminder.title.isEmpty {
            print("# Error: Can't add empty reminder")
            return
        }

        do {
            try self.eventStore.save(reminder, commit:true);
            print("Added reminder: \(reminder.title as Optional)")
        } catch {
            print("Failed to add reminder!")
        }
    }

    func update_reminder(reminder: EKReminder, priority:Int) throws {
        let key:String = NSString(format:"%03X", reminder.hash & 0xFFF) as String
        self.reminders[key] = reminder
        reminder.priority = priority
        try self.eventStore.save(reminder, commit:true);
    }

    func move_reminder(args:[String]) {
        // first arg is new priority.   Rest are hashes of items to move

        var priority:Int = 0;
        switch (args[0]) {
            case "uih":
                priority = 1
            case "ui":
                priority = 2
            case "uil":
                priority = 3
            case "nuih":
                priority = 4
            case "nui":
                priority = 5
            case "nuil":
                priority = 6
            case "unih":
                priority = 7
            case "uni":
                priority = 8
            case "unil":
                priority = 9
            case "nuni":
                priority = 0
            default:
                print("# Error: unrecognized priority (expected ui nui uni nuni)")
                return
        }
        for reminder in self.reminders.values {
            if (reminder.isCompleted) && (!reminder.completedToday) {
                continue
            }
            for arg in args[0..<args.count] {
                let hash = arg.uppercased()
                let key:String = NSString(format:"%03X", reminder.hash & 0xFFF) as String
                if hash == key {
                    do {
                        try self.update_reminder(reminder: reminder, priority: priority)
                    } catch {
                        print("Failed to move reminder!")
                    }

                }
            }
        }
    }

    func delete_reminder(args:[String]) throws {
        for reminder in self.reminders.values {
            if (reminder.isCompleted) && (!reminder.completedToday) {
                continue
            }
            for arg in args[0..<args.count] {
                let hash = arg.uppercased()
                let key:String = NSString(format:"%03X", reminder.hash & 0xFFF) as String
                if hash == key {
                    let title:String = reminder.title
                    try self.eventStore.remove(reminder, commit:true);
                    print("Deleted reminder: \(title)")
                    self.reminders[hash] = nil
                }
            }
        }
    }

    func complete_reminder(args:[String]) throws {
        for reminder in self.reminders.values {
            if (reminder.isCompleted) && (!reminder.completedToday) {
                continue
            }
            for arg in args[0..<args.count] {
                let hash = arg.uppercased()
                let key:String = NSString(format:"%03X", reminder.hash & 0xFFF) as String
                if hash == key {
                    reminder.isCompleted = true
                    try self.eventStore.save(reminder, commit:true);
                    print("Completed reminder: \(reminder.title as Optional)")
                }
            }
        }
    }

}
