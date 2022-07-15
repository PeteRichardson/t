
import EventKit

typealias ReminderDict = [String: EKReminder]

extension ReminderDict {
    // Return a dict of Reminders with priorities in the specied range
    func remindersWithPriorities(_ priorities: [Int]) -> ReminderDict {
        return self.filter { _, reminder in
                return priorities.contains(reminder.priority)
        }
    }
    
    var uiItems:   ReminderDict { get { remindersWithPriorities([1,2,3]) } }  // urgent and important items
    var nuiItems:  ReminderDict { get { remindersWithPriorities([4,5,6]) } }  // not urgent but important items
    var uniItems:  ReminderDict { get { remindersWithPriorities([7,8,9]) } }  // urgent but not important items
    var nuniItems: ReminderDict { get { remindersWithPriorities(  [0]  ) } }  // not urgent and not important items
}

class ReminderCache {
    enum Error : Swift.Error {
        case EmptyTitleError
    }
    
    var eventStore: EKEventStore
    var reminders = ReminderDict()

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
    
    func updateReminder(reminder: EKReminder, priority:Int? = nil, isCompleted: Bool? = nil) throws {
        self.reminders[reminder.key] = reminder
        if let priority {
            reminder.priority = priority
        }
        if let isCompleted {
            reminder.isCompleted = isCompleted
        }
        try self.eventStore.save(reminder, commit:true);
    }
    
    func addReminder(title: String, priority:Int) throws {
        guard (!title.isEmpty) else {
            throw ReminderCache.Error.EmptyTitleError
        }
        
        let reminder = EKReminder(eventStore: self.eventStore)
        reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
        reminder.title = title
        reminder.priority = priority

        try self.updateReminder(reminder: reminder, priority: priority)
    }


    func moveReminders(hashes: [String], priority: Int) throws {
        for hash in hashes {
            if let reminder = reminders[hash] {
                try self.updateReminder(reminder: reminder, priority: priority)
            }
        }
    }

    func deleteReminders(hashes:[String]) throws {
        for hash in hashes {
            if let reminder = reminders[hash] {
                try self.eventStore.remove(reminder, commit:true)
                self.reminders[hash] = nil
            }
        }
    }

    func completeReminders(hashes:[String]) throws {
        for hash in hashes {
            if let reminder = reminders[hash] {
                try self.updateReminder(reminder: reminder, isCompleted: true)
             }
        }
    }

}
