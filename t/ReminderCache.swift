
import EventKit

typealias ReminderDict = [String: EKReminder]

class ReminderCache {
    var eventStore: EKEventStore
    var reminders = ReminderDict()
    var leftMaxWidth:Int = 0
    var rightMaxWidth:Int = 0
    
    var uiItems:   ReminderDict { get { remindersWithPriorities(1...3) } }  // urgent and important items
    var nuiItems:  ReminderDict { get { remindersWithPriorities(4...6) } }  // not urgent but important items
    var uniItems:  ReminderDict { get { remindersWithPriorities(7...9) } }  // urgent but not important items
    var nuniItems: ReminderDict { get { remindersWithPriorities(0...0) } }  // not urgent and not important items

    init() {
	    self.eventStore = EKEventStore()
	    eventStore.requestAccess(to: EKEntityType.reminder, completion: {
	        (granted, error) in
	        if (!granted) || (error != nil) {
	            print("Reminder access denied!")
                exit(EXIT_FAILURE)
	        }
	    })
        self.loadReminders()
    }
    
    func loadReminders() {
        let cal = self.eventStore.defaultCalendarForNewReminders()
        let predicate = self.eventStore.predicateForReminders(in: [cal!])
        self.eventStore.fetchReminders(matching: predicate) { foundReminders in
            guard let foundReminders else { return }
            for reminder in foundReminders {
                // only load reminders that are not completed or were completed today
                guard !reminder.isCompleted || reminder.completedToday else { continue }
                self.reminders[reminder.key] = reminder
            }
        }
        Thread.sleep(forTimeInterval: 0.08)
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
            try self.update_reminder(reminder: reminder, priority: priority)
        } catch {
            print("Failed to add reminder!")
        }
    }

    func update_reminder(reminder: EKReminder, priority:Int) throws {
        self.reminders[reminder.key] = reminder
        reminder.priority = priority
        try self.eventStore.save(reminder, commit:true);
    }

    func move_reminder(args:[String], priority: Int) {
        // args is list of item hashes to move to new priority
        for reminder in self.reminders.values {
            if (reminder.isCompleted) && (!reminder.completedToday) {
                continue
            }
            for arg in args[0..<args.count] {
                let hash = arg.uppercased()
                if hash == reminder.key {
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
                if hash == reminder.key {
                    try self.eventStore.remove(reminder, commit:true);
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
                if hash == reminder.key {
                    reminder.isCompleted = true
                    try self.eventStore.save(reminder, commit:true);
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
