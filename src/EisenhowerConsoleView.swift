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
            var i = width1
            var left: String = spaces
            if x < sortedList1.count {
                i += 8
                left = sortedList1[x].description + left
                if sortedList1[x].completed {
                    i += 8
                }
            }
            left = left.substringToIndex(left.startIndex.advancedBy(i))
            var right: String = spaces
            i = width2
            if x < sortedList2.count {
                i += 8
                right = sortedList2[x].description + right
                if sortedList2[x].completed {
                    i += 8
                }
            }
            right = right.substringToIndex(right.startIndex.advancedBy(i))
            print("\u{2502} \(left) \u{2502} \(right) \u{2502}")
        }
    }

    // Given the four separate lists, dump them to the console.
	func display(uiItems: [String: EKReminder], nuiItems: [String: EKReminder], uniItems: [String: EKReminder], nuniItems: [String: EKReminder], maxWidth: Int) {
        // Use box drawing characters to make a prettier border around the lists.
        // see https://en.wikipedia.org/wiki/Box-drawing_character
        if maxWidth < self.leftcols {
            self.leftcols = maxWidth
        }
        if maxWidth < self.rightcols {
            self.rightcols = maxWidth
        }
        let leftcolborder = String(count: self.leftcols + 2,repeatedValue: Character("\u{2500}"))
        let rightcolborder = String(count: self.rightcols + 2,repeatedValue: Character("\u{2500}"))
        
        print("\u{1B}[m")
        print("\u{256D}" + leftcolborder + "\u{252C}" + rightcolborder + "\u{256E}")
	    self.list_reminders_side_by_side(uiItems, list2:nuiItems, width1:self.leftcols, width2:self.rightcols)
	    print("\u{251C}" + leftcolborder + "\u{253C}" + rightcolborder + "\u{2524}")
	    self.list_reminders_side_by_side(uniItems, list2:nuniItems, width1:self.leftcols, width2:self.rightcols)
	    print("\u{2570}" + leftcolborder + "\u{2534}" + rightcolborder + "\u{256F}")
	}
}