
import EventKit

typealias ReminderDict = [String: EKReminder]

let priority_map = [
	"uih":  1,
	"ui":   2,
	"uil":  3,
	"nuih": 4,
	"nui":  5,
	"nuil": 6,
	"unih": 7,
	"uni":  8,
	"unil": 9,
	"nuni": 0
]

class ReminderCache {
    var eventStore: EKEventStore
    var reminders = ReminderDict()
    var leftMaxWidth:Int = 0
    var rightMaxWidth:Int = 0
    
    var uiItems:   ReminderDict { get { remindersWithPriorities(1...3) } }
    var nuiItems:  ReminderDict { get { remindersWithPriorities(4...6) } }
    var uniItems:  ReminderDict { get { remindersWithPriorities(7...9) } }
    var nuniItems: ReminderDict { get { remindersWithPriorities(0...0) } }

 
    init() {
	    self.eventStore = EKEventStore()
	    eventStore.requestAccess(to: EKEntityType.reminder, completion: {
	        (granted, error) in
	        if (!granted) || (error != nil) {
	            print("Reminder access denied!")
                exit(EXIT_FAILURE)
	        }
	    })
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

        let priority:Int = priority_map[args[0]] ?? 0;
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

    // Return a dict of Reminders with priorities in the specied range
    func remindersWithPriorities(_ range: ClosedRange<Int>) -> ReminderDict {
        return self.reminders.filter { _, reminder in
                return range.contains(reminder.priority)
        }
    }


}
