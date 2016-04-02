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

    func format(rem: EKReminder, width: Int) -> String {
        let checkColor = 120
        let hashColor  = 210
        let titleColorNotCompleted = 255
        let titleColorCompleted = 238

        let completed : String = rem.completed ? "\u{1B}[38;5;\(checkColor)m✔\u{1B}[m" : " "
        let hash = NSString(format:"\u{1B}[38;5;\(hashColor)m%02X\u{1B}[m", rem.hash & 0xFF)
        let titleColor:Int = rem.completed ? titleColorCompleted : titleColorNotCompleted
        var titleText:String = rem.title + String(count: width,repeatedValue: Character(" "))
        titleText = titleText.substringToIndex(titleText.startIndex.advancedBy(width-6))
        let title = "\u{1B}[38;5;\(titleColor)m\(titleText)\u{1B}[m"
        return "\(completed)  \(hash) \(title)"
    }


	func list_reminders_side_by_side(list1: [String: EKReminder], list2: [String: EKReminder], width1: Int, width2: Int) {
        let rowCount = list1.count > list2.count ? list1.count : list2.count
        var sortedList1 = list1.values.sort() { (r1, r2) in
            return r2.completed
        }
        var sortedList2 = list2.values.sort() { (r1, r2) in
            return r2.completed
        }
        
        for row in 0..<rowCount {
            var left: String = String(count: width1,repeatedValue: Character(" "))
            if row < sortedList1.count {
                left = self.format(sortedList1[row], width: width1)
            }
            var right: String = String(count: width2,repeatedValue: Character(" "))
            if row < sortedList2.count {
                right = self.format(sortedList2[row], width: width2)
            }
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