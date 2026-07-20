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

}
