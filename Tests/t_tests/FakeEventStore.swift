//
//  FakeEventStore.swift
//  t_tests
//
//  Test double for EventStoring: records save/remove/commit calls instead of touching the
//  user's real Reminders database, so tests can exercise ReminderCache's mutate-and-save
//  happy path.
//

import EventKit
@testable import t

final class FakeEventStore: EventStoring {
    private(set) var savedReminders: [(reminder: EKReminder, commit: Bool)] = []
    private(set) var removedReminders: [(reminder: EKReminder, commit: Bool)] = []
    private(set) var commitCount = 0

    var saveError: Error?
    var removeError: Error?
    var commitError: Error?

    func save(_ reminder: EKReminder, commit: Bool) throws {
        if let saveError { throw saveError }
        savedReminders.append((reminder, commit))
    }

    func remove(_ reminder: EKReminder, commit: Bool) throws {
        if let removeError { throw removeError }
        removedReminders.append((reminder, commit))
    }

    func commit() throws {
        if let commitError { throw commitError }
        commitCount += 1
    }
}
