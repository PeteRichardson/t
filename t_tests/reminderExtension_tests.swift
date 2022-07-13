//
//  reminderExtension_tests.swift
//  t_tests
//
//  Created by Peter Richardson on 7/13/22.
//

import XCTest
import EventKit

final class reminderExtension_tests: XCTestCase {

    func testCompletionDateFalse() throws {
        let SECONDS_PER_DAY = 60 * 60 * 24 + 1
        let yesterday = Date.init(timeIntervalSinceNow: TimeInterval(-SECONDS_PER_DAY))
        
        let reminder = EKReminder(eventStore: EKEventStore())
        reminder.completionDate = yesterday
        XCTAssertFalse(reminder.completedToday)
    }
    
    func testCompletionDateTrue() throws {
        let reminder = EKReminder(eventStore: EKEventStore())
        reminder.completionDate = Date.now
        XCTAssertTrue(reminder.completedToday)
    }

}
