
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

    init() async {
	    self.eventStore = EKEventStore()
	    eventStore.requestAccess(to: EKEntityType.reminder, completion: {
	        (granted, error) in
	        if (!granted) || (error != nil) {
	            print("Reminder access denied!")
                exit(EXIT_FAILURE)
	        }
	    })
        for reminder in await fetchReminders() {
            self.reminders[reminder.key] = reminder
        }
    }
    
    
    func fetchReminders() async -> [EKReminder] {
        
        // need an EKCalendar and an NSPredicate to fetchReminders.
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            print("# ERROR: Could not get default calendar for new reminders!")
            return []
        }
        let predicate = eventStore.predicateForReminders(in: [calendar])
        
        /// Wrap old-style fetchReminders function (that takes a completion handler)
        /// with an async block that uses a continuation.
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { foundReminders in
                guard let foundReminders else {
                    continuation.resume(returning: [])
                    return
                }
            
                // This is our chance to filter/process the reminders before returning them.
                let filteredReminders = foundReminders.filter { !$0.isCompleted || $0.completedToday }
                continuation.resume(returning: filteredReminders)
            }
            // Careful! Every path in this withCheckedContinuation block
            // _must_ resume() the continuation or memory will leak.
            // Not a crisis in this short-lived app, but...
        }
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
