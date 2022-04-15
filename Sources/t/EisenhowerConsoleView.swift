import EventKit
import Darwin


public class EisenhowerConsoleView {
	var cols:Int = 80
	var leftcols:Int
	var rightcols:Int

	init() {
        var w = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
            //print("rows:", w.ws_row, "cols", w.ws_col)
            self.cols = Int(w.ws_col)
        }
        self.leftcols = Int(Double(self.cols) * 0.5)
		self.rightcols = Int(self.cols) - self.leftcols
        //print("cols = \(self.cols)")
        //print("leftcols = \(self.leftcols)")
        //print("rightcols = \(self.rightcols)")
	}

    func format(rem: EKReminder, width: Int) -> String {
        let checkColor = 120
        let hashColor  = 210
        let titleColorNotCompleted = 255
        let titleColorCompleted = 238

        //print("width = \(width)")


        let completed : String = rem.isCompleted ? "\u{1B}[38;5;\(checkColor)m✔\u{1B}[m" : " "
        let hash = String(format:"\u{1B}[38;5;\(hashColor)m%03X\u{1B}[m", rem.hash & 0xFFF)
        let titleColor:Int = rem.isCompleted ? titleColorCompleted : titleColorNotCompleted
        var titleText:String = String(rem.priority) + " " + rem.title + String(repeating: " ", count: width)
        //print ("titleText width = \(titleText.characters.count)")
        let index = titleText.index(titleText.startIndex, offsetBy: width-4)
        titleText = String(titleText[..<index])
        //print ("titleText width2 = \(titleText.characters.count)")
        let title = "\u{1B}[38;5;\(titleColor)m\(titleText)\u{1B}[m"
        return "\(completed)  \(hash) \(title)"
    }


	func list_reminders_side_by_side(list1: [String: EKReminder], list2: [String: EKReminder], width1: Int, width2: Int) {
        //print("width1 (leftcols) = \(width1)")
        //print("width2 (rightcols) = \(width2)")

        let rowCount = list1.count > list2.count ? list1.count : list2.count
        let sortedList1 = list1.values.sorted() { (r1, r2) in
            if r1.isCompleted == r2.isCompleted {
                return r1.priority < r2.priority
            } else {
                return r2.isCompleted
            }
        }
        let sortedList2 = list2.values.sorted() { (r1, r2) in
            if r1.isCompleted == r2.isCompleted {
                return r1.priority < r2.priority
            } else {
                return r2.isCompleted
            }
        }
        
        for row in 0..<rowCount {
            var left: String = String(repeating: " ", count: width1 - 4)
            if row < sortedList1.count {
                left = self.format(rem: sortedList1[row], width: width1-7)
            }
            var right: String = String(repeating: " ", count: width2-3)
            if row < sortedList2.count {
                right = self.format(rem: sortedList2[row], width: width2-6)
            }
            print("\u{2502} \(left) \u{2502} \(right) \u{2502}")
        }
    }

    // Given the four separate lists, dump them to the console.
	func display(uiItems: [String: EKReminder], nuiItems: [String: EKReminder], uniItems: [String: EKReminder], nuniItems: [String: EKReminder], leftMaxWidth: Int, rightMaxWidth: Int) {
        // Use box drawing characters to make a prettier border around the lists.
        // see https://en.wikipedia.org/wiki/Box-drawing_character
        if leftMaxWidth < self.leftcols {
            self.leftcols = leftMaxWidth
            //print("reset leftcols = \(self.leftcols)")
        }
        if rightMaxWidth < self.rightcols {
            self.rightcols = rightMaxWidth
            //print("reset rightcols = \(self.rightcols)")
        }
        if leftMaxWidth + rightMaxWidth <= self.cols {
            self.leftcols = leftMaxWidth
            self.rightcols = rightMaxWidth
            //print("reset again leftcols = \(self.leftcols)")
            //print("reset again rightcols = \(self.rightcols)")
       }

        let leftcolborder = String(repeating: "\u{2500}", count: self.leftcols - 2)
        let rightcolborder = String(repeating: "\u{2500}", count: self.rightcols - 1)
        
        print("\u{1B}[m")
        print("\u{256D}" + leftcolborder + "\u{252C}" + rightcolborder + "\u{256E}")
	    self.list_reminders_side_by_side(list1: uiItems, list2:nuiItems, width1:self.leftcols, width2:self.rightcols)
	    print("\u{251C}" + leftcolborder + "\u{253C}" + rightcolborder + "\u{2524}")
	    self.list_reminders_side_by_side(list1: uniItems, list2:nuniItems, width1:self.leftcols, width2:self.rightcols)
	    print("\u{2570}" + leftcolborder + "\u{2534}" + rightcolborder + "\u{256F}")
	}
}
