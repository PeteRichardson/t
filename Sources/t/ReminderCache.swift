
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
	    eventStore.requestAccess(to: EKEntityType.reminder, completion: {
	        (granted, error) in
	        if (granted) && (error == nil) {
	            //print("Access granted!")
	        }
	    })
        self.leftMaxWidth = 0
        self.rightMaxWidth = 0
        self.reminders = [EKReminder]()
        self.loadItems()
        //print("leftMaxWidth = \(self.leftMaxWidth)")
        //print("rightMaxWidth = \(self.rightMaxWidth)")
    }
    
    func loadItems() {
        self.leftMaxWidth = 0
        self.rightMaxWidth = 0
        self.reminders = [EKReminder]()
        var fetched: Bool = false
        let cal = self.eventStore.defaultCalendarForNewReminders()
        
        let predicate = self.eventStore.predicateForReminders(in: [cal!])
        
        self.eventStore.fetchReminders(matching: predicate) { foundReminders in
            
            self.reminders = foundReminders
            
            for reminder in self.reminders {
                if (reminder.isCompleted) && (!reminder.completedToday) {
                    continue
                }
                let key:String = NSString(format:"%03X", reminder.hash & 0xFFF) as String
                //print("len(\(reminder.title) = \(reminder.title.count)")
                switch (reminder.priority) {
	                case 1,2,3:
	                    self.uiItems[key] = reminder
                        if reminder.title.count > self.leftMaxWidth {
                            self.leftMaxWidth = reminder.title.count
                            //print("ui - leftMaxWidth = \(self.leftMaxWidth)")
                        }
	                case 4,5,6:
	                    self.nuiItems[key] = reminder
                        if reminder.title.count > self.rightMaxWidth {
                            self.rightMaxWidth = reminder.title.count
                            //print("nui - rightMaxWidth = \(self.rightMaxWidth)")
                        }
	                case 7,8,9:
	                    self.uniItems[key] = reminder
                        if reminder.title.count > self.leftMaxWidth {
                            self.leftMaxWidth = reminder.title.count
                            //print("uni - leftMaxWidth = \(self.leftMaxWidth)")
                        }
	                case 0:
	                    self.nuniItems[key] = reminder
                        if reminder.title.count > self.rightMaxWidth {
                            self.rightMaxWidth = reminder.title.count
                            //print("nuni - rightMaxWidth = \(self.rightMaxWidth)")
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
        switch (reminder.priority) {
            case 1,2,3:
                self.uiItems[key] = nil
            case 4,5,6:
                self.nuiItems[key] = nil
            case 7,8,9:
                self.uniItems[key] = nil
            case (0):
                self.nuniItems[key] = nil
            default:
                print("Unexpected priority");
        }
        reminder.priority = priority
        try self.eventStore.save(reminder, commit:true);
        switch (reminder.priority) {
            case 1,2,3:
                self.uiItems[key] = reminder
            case 4,5,6:
                self.nuiItems[key] = reminder
            case 7,8,9:
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
        for reminder in self.reminders {
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
        for reminder in self.reminders {
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

                    if let _ : EKReminder = self.uiItems[hash] {
                        self.uiItems[hash] = nil
                    } else if let _ : EKReminder = self.nuiItems[hash] {
                        self.nuiItems[hash] = nil
                    } else if let _ : EKReminder = self.uniItems[hash] {
                        self.uniItems[hash] = nil
                    } else if let _ : EKReminder = self.nuniItems[hash] {
                        self.nuniItems[hash] = nil
                    }

                }
            }
        }
    }

    func complete_reminder(args:[String]) throws {
        for reminder in self.reminders {
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
