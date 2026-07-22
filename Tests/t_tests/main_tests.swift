//
//  main_tests.swift
//  t_tests
//

import XCTest
import EventKit
@testable import t

final class main_tests: XCTestCase {

    private func reminder(priority: Int) -> EKReminder {
        let reminder = EKReminder(eventStore: EKEventStore())
        reminder.priority = priority
        return reminder
    }

    // MARK: - no command

    func testRun_emptyArgs_returnsRender() throws {
        let cache = ReminderCache(eventStore: EKEventStore())

        XCTAssertEqual(try runCommand(args: [], cache: cache), .render)
    }

    // MARK: - h / -h / --help

    func testRun_helpCommands_returnShowUsage() throws {
        let cache = ReminderCache(eventStore: EKEventStore())

        for helpArg in ["h", "-h", "--help"] {
            XCTAssertEqual(try runCommand(args: [helpArg], cache: cache), .showUsage)
        }
    }

    // MARK: - c / d argument validation (see #23)

    func testRun_completeCommand_noHashes_throwsInvalidArguments() throws {
        let cache = ReminderCache(eventStore: EKEventStore())

        XCTAssertThrowsError(try runCommand(args: ["c"], cache: cache)) { error in
            guard case RunError.invalidArguments(let message) = error else {
                XCTFail("Expected RunError.invalidArguments, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("'c' requires at least one hash"))
        }
    }

    func testRun_deleteCommand_noHashes_throwsInvalidArguments() throws {
        let cache = ReminderCache(eventStore: EKEventStore())

        XCTAssertThrowsError(try runCommand(args: ["d"], cache: cache)) { error in
            guard case RunError.invalidArguments(let message) = error else {
                XCTFail("Expected RunError.invalidArguments, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("'d' requires at least one hash"))
        }
    }

    func testRun_completeCommand_unknownHash_returnsRenderAndLeavesCacheUnchanged() throws {
        let known = reminder(priority: 1)
        let cache = ReminderCache(eventStore: EKEventStore(), reminders: ["aaa": known])

        let action = try runCommand(args: ["c", "zzz"], cache: cache)

        XCTAssertEqual(action, .render)
        XCTAssertEqual(cache.reminders.count, 1)
        XCTAssertEqual(cache.reminders["aaa"]?.isCompleted, false)
    }

    func testRun_deleteCommand_unknownHash_returnsRenderAndLeavesCacheUnchanged() throws {
        let known = reminder(priority: 1)
        let cache = ReminderCache(eventStore: EKEventStore(), reminders: ["aaa": known])

        let action = try runCommand(args: ["d", "zzz"], cache: cache)

        XCTAssertEqual(action, .render)
        XCTAssertEqual(cache.reminders.count, 1)
        XCTAssertNotNil(cache.reminders["aaa"])
    }

    // MARK: - m argument validation

    func testRun_moveCommand_missingPriority_throwsInvalidArguments() throws {
        let cache = ReminderCache(eventStore: EKEventStore())

        XCTAssertThrowsError(try runCommand(args: ["m"], cache: cache)) { error in
            guard case RunError.invalidArguments(let message) = error else {
                XCTFail("Expected RunError.invalidArguments, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("'m' requires a valid priority"))
        }
    }

    func testRun_moveCommand_invalidPriorityName_throwsInvalidArguments() throws {
        let cache = ReminderCache(eventStore: EKEventStore())

        XCTAssertThrowsError(try runCommand(args: ["m", "bogus"], cache: cache))
    }

    func testRun_moveCommand_unknownHash_returnsRenderAndLeavesCacheUnchanged() throws {
        let known = reminder(priority: 1)
        let cache = ReminderCache(eventStore: EKEventStore(), reminders: ["aaa": known])

        let action = try runCommand(args: ["m", "ui", "zzz"], cache: cache)

        XCTAssertEqual(action, .render)
        XCTAssertEqual(cache.reminders["aaa"]?.priority, 1)
    }

    // MARK: - default command (add reminder)

    func testRun_defaultCommand_emptyTitle_throwsEmptyTitleError() throws {
        let cache = ReminderCache(eventStore: EKEventStore())

        XCTAssertThrowsError(try runCommand(args: ["ui"], cache: cache)) { error in
            guard case ReminderCache.Error.EmptyTitleError = error else {
                XCTFail("Expected EmptyTitleError, got \(error)")
                return
            }
        }
    }
}
