
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

    /**
     Splits the dict by the load invariant (every reminder should be either not completed,
     or completed today). Reminders satisfying it come back as `valid`; any that don't
     (e.g. completed on a previous day, which the load predicates shouldn't produce but
     which external EventKit behavior could) come back as `invalid` instead of being
     silently rendered or trapping the process.
     */
    func partitionedByLoadInvariant() -> (valid: ReminderDict, invalid: ReminderDict) {
        var valid = ReminderDict()
        var invalid = ReminderDict()
        for (key, reminder) in self {
            if !reminder.isCompleted || reminder.completedToday {
                valid[key] = reminder
            } else {
                invalid[key] = reminder
            }
        }
        return (valid, invalid)
    }
    
    /**
     Build a ReminderDict keyed by `key(_:)` (defaults to `.key`), reporting any reminders whose
     key collided with one already inserted (and were therefore dropped) instead of silently
     overwriting them.
     */
    static func build(from reminders: [EKReminder], key: (EKReminder) -> String = { $0.key }) -> (dict: ReminderDict, collisions: [EKReminder]) {
        var dict = ReminderDict()
        var collisions: [EKReminder] = []
        for reminder in reminders {
            let k = key(reminder)
            if dict[k] != nil {
                collisions.append(reminder)
            } else {
                dict[k] = reminder
            }
        }
        return (dict, collisions)
    }

    /**
     Splits the dict by whether each reminder's `priority` maps to a known `Priority` case
     (0-9). Reminders with a recognized priority come back as `recognized`; any with an
     out-of-range priority (e.g. set by another app or import) come back as `unrecognized`
     instead of silently matching no quadrant and never rendering.
     */
    func partitionedByRecognizedPriority() -> (recognized: ReminderDict, unrecognized: ReminderDict) {
        var recognized = ReminderDict()
        var unrecognized = ReminderDict()
        for (key, reminder) in self {
            if Priority(rawValue: reminder.priority) != nil {
                recognized[key] = reminder
            } else {
                unrecognized[key] = reminder
            }
        }
        return (recognized, unrecognized)
    }
}

/**
 The subset of `EKEventStore` that mutates and persists a reminder. `EKEventStore` already
 satisfies this structurally (see the extension below) -- the seam exists so tests can inject a
 fake instead of touching the user's real Reminders database.
 */
protocol EventStoring {
    func save(_ reminder: EKReminder, commit: Bool) throws
    func remove(_ reminder: EKReminder, commit: Bool) throws
    func commit() throws
}

extension EKEventStore: EventStoring {}

class ReminderCache {
    enum Error : Swift.Error {
        case EmptyTitleError
    }

    var eventStore: EKEventStore
    var eventStoring: EventStoring
    var reminders = ReminderDict()

    /**
     Test-only initializer: bypasses the Reminders permission prompt and real EventKit fetch,
     so tests can exercise cache logic without touching the user's actual Reminders data.
     `eventStoring` defaults to `eventStore` itself (real save/remove/commit calls); pass a fake
     to also exercise the mutate-and-save happy path without touching real Reminders data.
     */
    init(eventStore: EKEventStore, eventStoring: EventStoring? = nil, reminders: ReminderDict = ReminderDict()) {
        self.eventStore = eventStore
        self.eventStoring = eventStoring ?? eventStore
        self.reminders = reminders
    }

    init() async {
        self.eventStore = EKEventStore()
        self.eventStoring = self.eventStore
        let granted = await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: EKEntityType.reminder) { granted, error in
                continuation.resume(returning: granted && error == nil)
            }
        }
        guard granted else {
            print("# Reminder access denied!")
            exit(EXIT_FAILURE)
        }
        let (dict, collisions) = ReminderDict.build(from: await fetchReminders())
        self.reminders = dict
        if !collisions.isEmpty {
            print("# WARNING: \(collisions.count) reminder(s) dropped due to a hash key collision")
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
    
    func updateReminder(reminder: EKReminder, priority:Int? = nil, isCompleted: Bool? = nil, commit: Bool = true) throws {
        self.reminders[reminder.key] = reminder
        if let priority {
            reminder.priority = priority
        }
        if let isCompleted {
            reminder.isCompleted = isCompleted
        }
        try self.eventStoring.save(reminder, commit: commit);
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
        var didMutate = false
        for hash in hashes {
            if let reminder = reminders[hash] {
                try self.updateReminder(reminder: reminder, priority: priority, commit: false)
                didMutate = true
            }
        }
        if didMutate {
            try self.eventStoring.commit()
        }
    }

    func deleteReminders(hashes:[String]) throws {
        var didMutate = false
        for hash in hashes {
            if let reminder = reminders[hash] {
                try self.eventStoring.remove(reminder, commit:false)
                self.reminders[hash] = nil
                didMutate = true
            }
        }
        if didMutate {
            try self.eventStoring.commit()
        }
    }

    func completeReminders(hashes:[String]) throws {
        var didMutate = false
        for hash in hashes {
            if let reminder = reminders[hash] {
                try self.updateReminder(reminder: reminder, isCompleted: true, commit: false)
                didMutate = true
            }
        }
        if didMutate {
            try self.eventStoring.commit()
        }
    }
    
}
