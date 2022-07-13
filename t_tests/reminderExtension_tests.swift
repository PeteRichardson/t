//
//  reminderExtension_tests.swift
//
//  Created by Peter Richardson on 7/13/22.
//

import XCTest
import EventKit

final class reminderExtension_tests: XCTestCase {

    /**
     Expect that a reminder completed more than 24 hours ago was NOT completed today
     */
    func testCompletionDateFalse() throws {
        let SECONDS_PER_DAY = 60 * 60 * 24 + 1
        let yesterday = Date.init(timeIntervalSinceNow: TimeInterval(-SECONDS_PER_DAY))
        
        let reminder = EKReminder(eventStore: EKEventStore())
        reminder.completionDate = yesterday
        XCTAssertFalse(reminder.completedToday)
    }
    
    /**
     Expect that a reminder completed Now was completed today
     */
    func testCompletionDateTrue() throws {
        let reminder = EKReminder(eventStore: EKEventStore())
        reminder.completionDate = Date.now
        XCTAssertTrue(reminder.completedToday)
    }
    
    /**
     Expect that a reminder with a nil completion date was NOT completed today
     */
    func testCompletionDateNil() throws {
        let reminder = EKReminder(eventStore: EKEventStore())
        reminder.completionDate = nil
        XCTAssertFalse(reminder.completedToday)
    }

}
