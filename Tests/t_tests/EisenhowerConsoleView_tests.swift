//
//  EisenhowerConsoleView_tests.swift
//  t_tests
//

import XCTest
import EventKit
@testable import t

final class EisenhowerConsoleView_tests: XCTestCase {

    private func reminder(priority: Int, title: String = "", isCompleted: Bool = false) -> EKReminder {
        let reminder = EKReminder(eventStore: EKEventStore())
        reminder.priority = priority
        reminder.title = title
        reminder.isCompleted = isCompleted
        return reminder
    }

    private func view(reminders: ReminderDict = [:]) -> EisenhowerConsoleView {
        let cache = ReminderCache(eventStore: EKEventStore(), reminders: reminders)
        return EisenhowerConsoleView(reminders: cache)
    }

    // MARK: - init: leftMaxWidth / rightMaxWidth

    func testInit_emptyCache_maxWidthsFallBackToThirteen() throws {
        let v = view()

        XCTAssertEqual(v.leftMaxWidth, 13)
        XCTAssertEqual(v.rightMaxWidth, 13)
    }

    func testInit_leftMaxWidth_usesLongestTitleAcrossBothLeftQuadrants() throws {
        let v = view(reminders: [
            "aaa": reminder(priority: 1, title: "short"),                    // urgentImportant (left)
            "bbb": reminder(priority: 7, title: "a much longer left title"), // urgentNotImportant (left)
            "ccc": reminder(priority: 4, title: "an even longer right-side title that should not count"), // right
        ])

        XCTAssertEqual(v.leftMaxWidth, "a much longer left title".count + 13)
    }

    func testInit_rightMaxWidth_usesLongestTitleAcrossBothRightQuadrants() throws {
        let v = view(reminders: [
            "aaa": reminder(priority: 4, title: "short"),                     // notUrgentImportant (right)
            "bbb": reminder(priority: 0, title: "a somewhat longer title"),   // notUrgentNotImportant (right)
            "ccc": reminder(priority: 1, title: "an even longer left-side title that should not count"), // left
        ])

        XCTAssertEqual(v.rightMaxWidth, "a somewhat longer title".count + 13)
    }

    // MARK: - format(rem:width:)

    func testFormat_incompleteReminder_hasNoCheckmark() throws {
        let v = view()
        let rem = reminder(priority: 2, title: "buy milk", isCompleted: false)

        let result = v.format(rem: rem, width: 40)

        XCTAssertTrue(result.contains(rem.key))
        XCTAssertTrue(result.contains(" 2 "))
        XCTAssertTrue(result.contains("buy milk"))
        XCTAssertFalse(result.contains("\u{2714}"))   // ✔
    }

    func testFormat_completedReminder_hasCheckmark() throws {
        let v = view()
        let rem = reminder(priority: 5, title: "done thing", isCompleted: true)

        let result = v.format(rem: rem, width: 40)

        XCTAssertTrue(result.contains("\u{2714}"))    // ✔
        XCTAssertTrue(result.contains(rem.key))
    }

    func testFormat_titleLongerThanWidth_isTruncatedToWidthMinusSix() throws {
        let v = view()
        let rem = reminder(priority: 0, title: String(repeating: "x", count: 100))

        let result = v.format(rem: rem, width: 20)

        XCTAssertTrue(result.contains(String(repeating: "x", count: 14)))
        XCTAssertFalse(result.contains(String(repeating: "x", count: 15)))
    }

    // MARK: - sortByCompletionAndPriority

    func testSort_bothIncomplete_ordersByPriorityAscending() throws {
        let v = view()
        let high = reminder(priority: 1)   // "high" importance within its quadrant
        let low  = reminder(priority: 3)   // "low" importance within its quadrant

        XCTAssertTrue(v.sortByCompletionAndPriority(r1: high, r2: low))
        XCTAssertFalse(v.sortByCompletionAndPriority(r1: low, r2: high))
    }

    func testSort_bothCompleted_ordersByPriorityAscending() throws {
        let v = view()
        let high = reminder(priority: 1, isCompleted: true)
        let low  = reminder(priority: 3, isCompleted: true)

        XCTAssertTrue(v.sortByCompletionAndPriority(r1: high, r2: low))
        XCTAssertFalse(v.sortByCompletionAndPriority(r1: low, r2: high))
    }

    func testSort_incompleteAlwaysBeforeCompleted_regardlessOfPriority() throws {
        let v = view()
        let incomplete = reminder(priority: 9, isCompleted: false)
        let completed  = reminder(priority: 1, isCompleted: true)

        XCTAssertTrue(v.sortByCompletionAndPriority(r1: incomplete, r2: completed))
        XCTAssertFalse(v.sortByCompletionAndPriority(r1: completed, r2: incomplete))
    }
}
