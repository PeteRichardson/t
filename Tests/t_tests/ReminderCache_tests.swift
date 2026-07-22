//
//  ReminderCache_tests.swift
//  t_tests
//
//  Created by Peter Richardson on 7/18/22.
//

import XCTest
import EventKit
@testable import t

final class ReminderCache_tests: XCTestCase {

    private func reminder(priority: Int) -> EKReminder {
        let reminder = EKReminder(eventStore: EKEventStore())
        reminder.priority = priority
        return reminder
    }

    private func reminder(isCompleted: Bool, completionDate: Date?) -> EKReminder {
        let reminder = EKReminder(eventStore: EKEventStore())
        reminder.isCompleted = isCompleted
        reminder.completionDate = completionDate
        return reminder
    }

    // MARK: - reminders(in:) / quadrant accessors

    func testRemindersInQuadrant_filtersToRequestedQuadrant() throws {
        let dict: ReminderDict = [
            "aaa": reminder(priority: 1),
            "bbb": reminder(priority: 2),
            "ccc": reminder(priority: 7),
            "ddd": reminder(priority: 0),
        ]

        let filtered = dict.reminders(in: .urgentImportant)

        XCTAssertEqual(Set(filtered.keys), Set(["aaa", "bbb"]))
    }

    func testUiItems_returnsPriorities1To3() throws {
        let dict: ReminderDict = [
            "aaa": reminder(priority: 1),
            "bbb": reminder(priority: 2),
            "ccc": reminder(priority: 3),
            "decoy": reminder(priority: 4),
        ]

        XCTAssertEqual(Set(dict.uiItems.keys), Set(["aaa", "bbb", "ccc"]))
    }

    func testNuiItems_returnsPriorities4To6() throws {
        let dict: ReminderDict = [
            "aaa": reminder(priority: 4),
            "bbb": reminder(priority: 5),
            "ccc": reminder(priority: 6),
            "decoy1": reminder(priority: 3),
            "decoy2": reminder(priority: 7),
        ]

        XCTAssertEqual(Set(dict.nuiItems.keys), Set(["aaa", "bbb", "ccc"]))
    }

    func testUniItems_returnsPriorities7To9() throws {
        let dict: ReminderDict = [
            "aaa": reminder(priority: 7),
            "bbb": reminder(priority: 8),
            "ccc": reminder(priority: 9),
            "decoy1": reminder(priority: 6),
            "decoy2": reminder(priority: 0),
        ]

        XCTAssertEqual(Set(dict.uniItems.keys), Set(["aaa", "bbb", "ccc"]))
    }

    func testNuniItems_returnsPriority0Only() throws {
        let dict: ReminderDict = [
            "aaa": reminder(priority: 0),
            "decoy1": reminder(priority: 1),
            "decoy2": reminder(priority: 9),
        ]

        XCTAssertEqual(Set(dict.nuniItems.keys), Set(["aaa"]))
    }

    // MARK: - partitionedByLoadInvariant

    func testPartitionedByLoadInvariant_incompleteReminder_isValid() throws {
        let dict: ReminderDict = ["aaa": reminder(isCompleted: false, completionDate: nil)]

        let (valid, invalid) = dict.partitionedByLoadInvariant()

        XCTAssertEqual(Set(valid.keys), Set(["aaa"]))
        XCTAssertTrue(invalid.isEmpty)
    }

    func testPartitionedByLoadInvariant_completedToday_isValid() throws {
        let dict: ReminderDict = ["aaa": reminder(isCompleted: true, completionDate: Date())]

        let (valid, invalid) = dict.partitionedByLoadInvariant()

        XCTAssertEqual(Set(valid.keys), Set(["aaa"]))
        XCTAssertTrue(invalid.isEmpty)
    }

    func testPartitionedByLoadInvariant_completedBeforeToday_isInvalid() throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let dict: ReminderDict = ["aaa": reminder(isCompleted: true, completionDate: yesterday)]

        let (valid, invalid) = dict.partitionedByLoadInvariant()

        XCTAssertTrue(valid.isEmpty)
        XCTAssertEqual(Set(invalid.keys), Set(["aaa"]))
    }

    func testPartitionedByLoadInvariant_mixedReminders_splitsCorrectly() throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let dict: ReminderDict = [
            "aaa": reminder(isCompleted: false, completionDate: nil),
            "bbb": reminder(isCompleted: true, completionDate: Date()),
            "ccc": reminder(isCompleted: true, completionDate: yesterday),
        ]

        let (valid, invalid) = dict.partitionedByLoadInvariant()

        XCTAssertEqual(Set(valid.keys), Set(["aaa", "bbb"]))
        XCTAssertEqual(Set(invalid.keys), Set(["ccc"]))
    }

    // MARK: - partitionedByRecognizedPriority

    func testPartitionedByRecognizedPriority_priorityInRange_isRecognized() throws {
        let dict: ReminderDict = ["aaa": reminder(priority: 5)]

        let (recognized, unrecognized) = dict.partitionedByRecognizedPriority()

        XCTAssertEqual(Set(recognized.keys), Set(["aaa"]))
        XCTAssertTrue(unrecognized.isEmpty)
    }

    func testPartitionedByRecognizedPriority_priorityOutOfRange_isUnrecognized() throws {
        let dict: ReminderDict = ["aaa": reminder(priority: 42)]

        let (recognized, unrecognized) = dict.partitionedByRecognizedPriority()

        XCTAssertTrue(recognized.isEmpty)
        XCTAssertEqual(Set(unrecognized.keys), Set(["aaa"]))
    }

    func testPartitionedByRecognizedPriority_mixedReminders_splitsCorrectly() throws {
        let dict: ReminderDict = [
            "aaa": reminder(priority: 1),
            "bbb": reminder(priority: 99),
            "ccc": reminder(priority: -1),
        ]

        let (recognized, unrecognized) = dict.partitionedByRecognizedPriority()

        XCTAssertEqual(Set(recognized.keys), Set(["aaa"]))
        XCTAssertEqual(Set(unrecognized.keys), Set(["bbb", "ccc"]))
    }

    // MARK: - addReminder

    func testAddReminder_emptyTitle_throwsEmptyTitleError() throws {
        let cache = ReminderCache(eventStore: EKEventStore())

        XCTAssertThrowsError(try cache.addReminder(title: "", priority: 1)) { error in
            guard case ReminderCache.Error.EmptyTitleError = error else {
                XCTFail("Expected EmptyTitleError, got \(error)")
                return
            }
        }
    }

    // MARK: - updateReminder / addReminder happy path (via FakeEventStore)

    func testAddReminder_validTitle_savesWithCommitTrue() throws {
        let fake = FakeEventStore()
        let cache = ReminderCache(eventStore: EKEventStore(), eventStoring: fake)

        try cache.addReminder(title: "buy milk", priority: 2)

        XCTAssertEqual(fake.savedReminders.count, 1)
        XCTAssertEqual(fake.savedReminders.first?.commit, true)
        XCTAssertEqual(fake.savedReminders.first?.reminder.title, "buy milk")
        XCTAssertEqual(fake.savedReminders.first?.reminder.priority, 2)
        XCTAssertEqual(cache.reminders.count, 1)
    }

    func testUpdateReminder_defaultCommit_savesWithCommitTrue() throws {
        let fake = FakeEventStore()
        let cache = ReminderCache(eventStore: EKEventStore(), eventStoring: fake)
        let rem = reminder(priority: 1)

        try cache.updateReminder(reminder: rem, priority: 5)

        XCTAssertEqual(rem.priority, 5)
        XCTAssertEqual(fake.savedReminders.count, 1)
        XCTAssertEqual(fake.savedReminders.first?.commit, true)
        XCTAssertTrue(cache.reminders[rem.key] === rem)
    }

    func testUpdateReminder_explicitCommitFalse_doesNotCommit() throws {
        let fake = FakeEventStore()
        let cache = ReminderCache(eventStore: EKEventStore(), eventStoring: fake)
        let rem = reminder(priority: 1)

        try cache.updateReminder(reminder: rem, isCompleted: true, commit: false)

        XCTAssertEqual(fake.savedReminders.first?.commit, false)
        XCTAssertEqual(fake.commitCount, 0)
    }

    func testUpdateReminder_saveThrows_propagatesError() throws {
        struct TestError: Error {}
        let fake = FakeEventStore()
        fake.saveError = TestError()
        let cache = ReminderCache(eventStore: EKEventStore(), eventStoring: fake)

        XCTAssertThrowsError(try cache.updateReminder(reminder: reminder(priority: 1), priority: 3))
    }

    // MARK: - ReminderDict.build(from:) collision handling

    func testBuild_noCollisions_keepsEveryReminder() throws {
        let a = reminder(priority: 1)
        let b = reminder(priority: 2)

        let (dict, collisions) = ReminderDict.build(from: [a, b]) { $0 === a ? "aaa" : "bbb" }

        XCTAssertEqual(Set(dict.keys), Set(["aaa", "bbb"]))
        XCTAssertTrue(collisions.isEmpty)
    }

    func testBuild_collidingKey_dropsLaterReminderAndReportsIt() throws {
        let first = reminder(priority: 1)
        let second = reminder(priority: 2)

        let (dict, collisions) = ReminderDict.build(from: [first, second]) { _ in "aaa" }

        XCTAssertEqual(dict.count, 1)
        XCTAssertTrue(dict["aaa"] === first)
        XCTAssertEqual(collisions.count, 1)
        XCTAssertTrue(collisions.first === second)
    }

    // MARK: - unknown-hash no-ops (moveReminders/deleteReminders/completeReminders)

    func testMoveReminders_unknownHash_leavesCacheUnchanged() throws {
        let known = reminder(priority: 1)
        let cache = ReminderCache(eventStore: EKEventStore(), reminders: ["aaa": known])

        try cache.moveReminders(hashes: ["zzz"], priority: 5)

        XCTAssertEqual(cache.reminders.count, 1)
        XCTAssertEqual(cache.reminders["aaa"]?.priority, 1)
    }

    func testDeleteReminders_unknownHash_leavesCacheUnchanged() throws {
        let known = reminder(priority: 1)
        let cache = ReminderCache(eventStore: EKEventStore(), reminders: ["aaa": known])

        try cache.deleteReminders(hashes: ["zzz"])

        XCTAssertEqual(cache.reminders.count, 1)
        XCTAssertNotNil(cache.reminders["aaa"])
    }

    func testCompleteReminders_unknownHash_leavesCacheUnchanged() throws {
        let known = reminder(priority: 1)
        let cache = ReminderCache(eventStore: EKEventStore(), reminders: ["aaa": known])

        try cache.completeReminders(hashes: ["zzz"])

        XCTAssertEqual(cache.reminders.count, 1)
        XCTAssertEqual(cache.reminders["aaa"]?.isCompleted, false)
    }

    // MARK: - known-hash happy path + batched commit (via FakeEventStore, see #22)

    func testMoveReminders_knownHash_updatesPriorityAndCommitsOnce() throws {
        let fake = FakeEventStore()
        let known = reminder(priority: 1)
        let cache = ReminderCache(eventStore: EKEventStore(), eventStoring: fake, reminders: ["aaa": known])

        try cache.moveReminders(hashes: ["aaa"], priority: 7)

        XCTAssertEqual(known.priority, 7)
        XCTAssertEqual(fake.savedReminders.count, 1)
        XCTAssertEqual(fake.savedReminders.first?.commit, false)   // save itself doesn't commit...
        XCTAssertEqual(fake.commitCount, 1)                        // ...moveReminders commits once after the loop
    }

    func testMoveReminders_multipleKnownHashes_commitsExactlyOnce() throws {
        let fake = FakeEventStore()
        let a = reminder(priority: 1)
        let b = reminder(priority: 2)
        let cache = ReminderCache(eventStore: EKEventStore(), eventStoring: fake, reminders: ["aaa": a, "bbb": b])

        try cache.moveReminders(hashes: ["aaa", "bbb"], priority: 9)

        XCTAssertEqual(a.priority, 9)
        XCTAssertEqual(b.priority, 9)
        XCTAssertEqual(fake.savedReminders.count, 2)
        XCTAssertEqual(fake.commitCount, 1)   // batched into a single commit, not one per hash
    }

    func testMoveReminders_mixOfKnownAndUnknownHashes_onlyMutatesKnownOnes() throws {
        let fake = FakeEventStore()
        let known = reminder(priority: 1)
        let cache = ReminderCache(eventStore: EKEventStore(), eventStoring: fake, reminders: ["aaa": known])

        try cache.moveReminders(hashes: ["aaa", "zzz"], priority: 6)

        XCTAssertEqual(known.priority, 6)
        XCTAssertEqual(fake.savedReminders.count, 1)
        XCTAssertEqual(fake.commitCount, 1)
    }

    func testMoveReminders_allUnknownHashes_neverCommits() throws {
        let fake = FakeEventStore()
        let cache = ReminderCache(eventStore: EKEventStore(), eventStoring: fake)

        try cache.moveReminders(hashes: ["zzz"], priority: 5)

        XCTAssertTrue(fake.savedReminders.isEmpty)
        XCTAssertEqual(fake.commitCount, 0)
    }

    func testDeleteReminders_knownHash_removesFromCacheAndCommitsOnce() throws {
        let fake = FakeEventStore()
        let known = reminder(priority: 1)
        let cache = ReminderCache(eventStore: EKEventStore(), eventStoring: fake, reminders: ["aaa": known])

        try cache.deleteReminders(hashes: ["aaa"])

        XCTAssertNil(cache.reminders["aaa"])
        XCTAssertEqual(fake.removedReminders.count, 1)
        XCTAssertEqual(fake.removedReminders.first?.commit, false)
        XCTAssertEqual(fake.commitCount, 1)
    }

    func testDeleteReminders_multipleKnownHashes_commitsExactlyOnce() throws {
        let fake = FakeEventStore()
        let a = reminder(priority: 1)
        let b = reminder(priority: 2)
        let cache = ReminderCache(eventStore: EKEventStore(), eventStoring: fake, reminders: ["aaa": a, "bbb": b])

        try cache.deleteReminders(hashes: ["aaa", "bbb"])

        XCTAssertTrue(cache.reminders.isEmpty)
        XCTAssertEqual(fake.removedReminders.count, 2)
        XCTAssertEqual(fake.commitCount, 1)
    }

    func testCompleteReminders_knownHash_marksCompletedAndCommitsOnce() throws {
        let fake = FakeEventStore()
        let known = reminder(priority: 1)
        let cache = ReminderCache(eventStore: EKEventStore(), eventStoring: fake, reminders: ["aaa": known])

        try cache.completeReminders(hashes: ["aaa"])

        XCTAssertEqual(known.isCompleted, true)
        XCTAssertEqual(fake.savedReminders.count, 1)
        XCTAssertEqual(fake.commitCount, 1)
    }

    func testCompleteReminders_multipleKnownHashes_commitsExactlyOnce() throws {
        let fake = FakeEventStore()
        let a = reminder(priority: 1)
        let b = reminder(priority: 2)
        let cache = ReminderCache(eventStore: EKEventStore(), eventStoring: fake, reminders: ["aaa": a, "bbb": b])

        try cache.completeReminders(hashes: ["aaa", "bbb"])

        XCTAssertTrue(a.isCompleted)
        XCTAssertTrue(b.isCompleted)
        XCTAssertEqual(fake.commitCount, 1)
    }

}
