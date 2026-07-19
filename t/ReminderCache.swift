
import EventKit

typealias ReminderDict = [String: EKReminder]

extension ReminderDict {
    // Return a dict of Reminders whose priority falls in the given quadrant
    func reminders(in quadrant: Priority.Quadrant) -> ReminderDict {
        return self.filter { _, reminder in
            return Priority(rawValue: reminder.priority)?.quadrant == quadrant
        }
    }

    var uiItems:   ReminderDict { get { reminders(in: .urgentImportant) } }        // urgent and important items
    var nuiItems:  ReminderDict { get { reminders(in: .notUrgentImportant) } }     // not urgent but important items
    var uniItems:  ReminderDict { get { reminders(in: .urgentNotImportant) } }     // urgent but not important items
    var nuniItems: ReminderDict { get { reminders(in: .notUrgentNotImportant) } }  // not urgent and not important items
}

class ReminderCache {
    enum Error : Swift.Error {
        case EmptyTitleError
    }
    
    var eventStore: EKEventStore
    var reminders = ReminderDict()
    
    init() async {
        self.eventStore = EKEventStore()
        let granted = await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: EKEntityType.reminder) { granted, error in
                continuation.resume(returning: granted && error == nil)
            }
        }
        guard granted else {
            print("Reminder access denied!")
            exit(EXIT_FAILURE)
        }
        for reminder in await fetchReminders() {
            self.reminders[reminder.key] = reminder
        }
    }
    
    /**
     Given a predicate, return a (possibly empty) array of matching reminders.
     Is Async.
     Does not return nil.
     
     Algorithm: simple wrap old-style fetchReminders function (that takes a completion handler)
     with an async block that uses a continuation.
     */
    func fetchReminders(matching predicate: NSPredicate) async -> [EKReminder] {
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { foundReminders in
                continuation.resume(returning: foundReminders)
            }
        } ?? []
    }
    
    /**
     Get all open reminders and all reminders completed today.
     */
    func fetchReminders() async -> [EKReminder] {
        // need an EKCalendar and an NSPredicate to fetchReminders.
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            print("# ERROR: Could not get default calendar for new reminders!")
            exit(EXIT_FAILURE)
        }
        
        // Get any reminders that are not completed
        let incompleteRemindersPredicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [calendar])
        let incompleteReminders = await fetchReminders(matching: incompleteRemindersPredicate)
        
        // Also get reminders that were completed today
        let completedTodayPredicate = eventStore.predicateForCompletedReminders(withCompletionDateStarting: Calendar.current.startOfDay(for: Date.now),
                                                                                ending: Date.now,
                                                                                calendars: [calendar])
        let completedTodayReminders = await fetchReminders(matching: completedTodayPredicate)
        
        return incompleteReminders + completedTodayReminders
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
