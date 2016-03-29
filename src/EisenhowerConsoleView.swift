import EventKit
import Cncurses
import Darwin.ncurses


public class EisenhowerConsoleView {
	var cols:Int
	var leftcols:Int
	var rightcols:Int

	init() {
        // Use curses to figure out the width of the screen
		initscr()
		self.cols = Int(COLS)
		self.leftcols = Int(Double(COLS) * 0.5) - 8
		self.rightcols = Int(COLS) - leftcols - 8
		endwin()
	}

	func list_reminders_side_by_side(list1: [String: EKReminder], list2: [String: EKReminder], width1: Int, width2: Int) {
        var rows = list1.count
        if list2.count > list1.count {
            rows = list2.count
        }
        var sortedList1 = list1.values.sort() { (r1, r2) in
            return r2.completed
        }
        var sortedList2 = list2.values.sort() { (r1, r2) in
            return r2.completed
        }
        
        let spaces = String(count: self.cols,repeatedValue: Character(" "))
        for x in 0..<rows {
            var left: String = spaces
            if x < sortedList1.count {
                left = sortedList1[x].description + left
            }
            left = left.substringToIndex(left.startIndex.advancedBy(width1))
            var right: String = spaces
            if x < sortedList2.count {
                right = sortedList2[x].description + right
            }
            right = right.substringToIndex(right.startIndex.advancedBy(width2))
            print("| \(left) | \(right) |")
        }
    }

    // Given the four separate lists, dump them to the console.
	func display(uiItems: [String: EKReminder], nuiItems: [String: EKReminder], uniItems: [String: EKReminder], nuniItems: [String: EKReminder], maxWidth: Int) {

        if maxWidth < self.leftcols {
            self.leftcols = maxWidth
        }
        if maxWidth < self.rightcols {
            self.rightcols = maxWidth
        }
        let separator = String(count: self.leftcols + self.rightcols + 7,repeatedValue: Character("-"))
        print(separator)
	    self.list_reminders_side_by_side(uiItems, list2:nuiItems, width1:self.leftcols, width2:self.rightcols)
	    print(separator)
	    self.list_reminders_side_by_side(uniItems, list2:nuniItems, width1:self.leftcols, width2:self.rightcols)
	    print(separator)
	}
}