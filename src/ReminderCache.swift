
import EventKit

class ReminderCache {
    var uiItems    = [String: EKReminder]()
    var nuiItems   = [String: EKReminder]()
    var uniItems   = [String: EKReminder]()
    var nuniItems  = [String: EKReminder]()
    var leftMaxWidth:Int
    var rightMaxWidth:Int
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
        self.leftMaxWidth = 0
        self.rightMaxWidth = 0
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
                        if reminder.title.characters.count > self.leftMaxWidth {
                            self.leftMaxWidth = reminder.title.characters.count
                        }
	                case (5):
	                    self.nuiItems[key] = reminder
                        if reminder.title.characters.count > self.rightMaxWidth {
                            self.rightMaxWidth = reminder.title.characters.count
                        }
	                case (9):
	                    self.uniItems[key] = reminder
                        if reminder.title.characters.count > self.leftMaxWidth {
                            self.leftMaxWidth = reminder.title.characters.count
                        }
	                case (0):
	                    self.nuniItems[key] = reminder
	                default:
	                    print("Unexpected priority");
                }
            }
            self.leftMaxWidth += 10
            self.rightMaxWidth += 10
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

    func update_reminder(reminder: EKReminder, priority:Int) throws {
        let key:String = NSString(format:"%02X", reminder.hash & 0xFF) as String
        switch (reminder.priority) {
            case (1):
                self.uiItems[key] = nil
            case (5):
                self.nuiItems[key] = nil
            case (9):
                self.uniItems[key] = nil
            case (0):
                self.nuniItems[key] = nil
            default:
                print("Unexpected priority");
        }
        reminder.priority = priority
        try self.eventStore.saveReminder(reminder, commit:true);
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

    func move_reminder(args:[String]) {
        // first arg is new priority.   Rest are hashes of items to move

        var priority:Int = 0;
        switch (args[0]) {
	        case "ui":
	            priority = 1
	        case "nui":
	            priority = 5
	        case "uni":
	            priority = 9
	        case "nuni":
	            priority = 0
	        default:
	            print("# Error: unrecognized priority (expected ui nui uni nuni)")
	            return
        }

        for arg in args[1..<args.count] {
            let hash = arg.uppercaseString
             do {
                let iItems : Bool = (self.uiItems[hash] == nil) && (self.nuiItems[hash] == nil)
                let uItems : Bool = (self.uniItems[hash] == nil) && (self.nuniItems[hash] == nil)
                if  iItems && uItems {
                    print("Error: no reminder with id \(hash)")
                    continue
                }
                if let reminder : EKReminder = self.uiItems[hash] {
                    try self.update_reminder(reminder, priority: priority)
                }
                if let reminder : EKReminder = self.nuiItems[hash] {
                    try self.update_reminder(reminder, priority: priority)
                }
                if let reminder : EKReminder = self.uniItems[hash] {
                    try self.update_reminder(reminder, priority: priority)
                }
                if let reminder : EKReminder = self.nuniItems[hash] {
                    try self.update_reminder(reminder, priority: priority)
                }
            } catch {
                print("Failed to move reminder!")
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
}
