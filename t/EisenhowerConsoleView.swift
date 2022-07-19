import EventKit
import Darwin


public class EisenhowerConsoleView {
	var cols:Int = 80
	var leftcols:Int
	var rightcols:Int
    // Note: these ...MaxWidth properties probably don't benefit from the lazy
    // keyword.  They are each executed exactly once for each execution,
    // and they aren't particularly slow.  User wouldn't notice.
    lazy var leftMaxWidth: Int = {
        let longestLeftTitle = remCache.reminders.values
            .filter { reminder in [1,2,3,7,8,9].contains(reminder.priority) }
            .map { $0.title.count }
            .max() ?? 0
        let result = longestLeftTitle + 13
        return result
    }()
    lazy var rightMaxWidth: Int = {
        let longestRightTitle = remCache.reminders.values
            .filter { reminder in [0,4,5,6].contains(reminder.priority) }
            .map { $0.title.count }
            .max() ?? 0
        let result = longestRightTitle + 13
        return result
    }()
    var remCache: ReminderCache

    // Map strings to the 10 priority levels in Reminders
    // Priority values specify which quadrant the item appears in
    // and the sorting inside the quadrant.
    //     uih (1)   |    nuih (4)
    //     ui  (2)   |    nui  (5)
    //     uil (3)   |    nuil (6)
    //   -----------------------
    //     uih (7)   |     
    //     ui  (8)   |    nuni (0)
    //     uil (9)   |     

    static let priority_map = [
        "uih":  1,         // urgent,     important (high)
        "ui":   2,         // urgent,     important (normal)
        "uil":  3,         // urgent,     important (low)
        "nuih": 4,         // not urgent, important (high)
        "nui":  5,         // not urgent, important (normal)
        "nuil": 6,         // not urgent, important (low)
        "unih": 7,         // urgent,     not important (high)
        "uni":  8,         // urgent,     not important (normal)
        "unil": 9,         // urgent,     not important (low)
        "nuni": 0,         // not urgent, not important
    
        "1":    1,         // urgent,     important (high)
        "2":    2,         // urgent,     important (normal)
        "3":    3,         // urgent,     important (low)
        "4":    4,         // not urgent, important (high)
        "5":    5,         // not urgent, important (normal)
        "6":    6,         // not urgent, important (low)
        "7":    7,         // urgent,     not important (high)
        "8":    8,         // urgent,     not important (normal)
        "9":    9,         // urgent,     not important (low)
        "0":    0          // not urgent, not important
    ]


	init(reminders: ReminderCache) {
        var w = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
            self.cols = Int(w.ws_col)
        }
        self.leftcols = Int(Double(self.cols) * 0.5)
		self.rightcols = Int(self.cols) - self.leftcols
        self.remCache = reminders
	}

    func format(rem: EKReminder, width: Int) -> String {
        let checkColor = 120
        let hashColor  = 210
        let titleColorNotCompleted = 255
        let titleColorCompleted = 238

        let completed : String = rem.isCompleted ? "\u{1B}[38;5;\(checkColor)m✔\u{1B}[m" : " "
        let hash = "\u{1B}[38;5;\(hashColor)m\(rem.key)\u{1B}[m"
        let titleColor:Int = rem.isCompleted ? titleColorCompleted : titleColorNotCompleted
        var titleText:String = String(rem.priority) + " " + rem.title + String(repeating: " ", count: width)
        let index = titleText.index(titleText.startIndex, offsetBy: width-4)
        titleText = String(titleText[..<index])
        let title = "\u{1B}[38;5;\(titleColor)m\(titleText)\u{1B}[m"
        return "\(completed)  \(hash) \(title)"
    }


	func list_reminders_side_by_side(list1: ReminderDict, list2: ReminderDict, width1: Int, width2: Int) {
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
	func display() {
        // Use box drawing characters to make a prettier border around the lists.
        // see https://en.wikipedia.org/wiki/Box-drawing_character
        if self.leftMaxWidth < self.leftcols {
            self.leftcols = self.leftMaxWidth
        }
        if self.rightMaxWidth < self.rightcols {
            self.rightcols = self.rightMaxWidth
        }
        if self.leftMaxWidth + self.rightMaxWidth <= self.cols {
            self.leftcols = self.leftMaxWidth
            self.rightcols = self.rightMaxWidth
       }
        
        let leftcolborder = String(repeating: "\u{2500}", count: self.leftcols - 2)
        let rightcolborder = String(repeating: "\u{2500}", count: self.rightcols - 1)
        
        print("\u{1B}[m")
        print("\u{256D}" + leftcolborder + "\u{252C}" + rightcolborder + "\u{256E}")
	    self.list_reminders_side_by_side(
            list1: self.remCache.reminders.uiItems,
            list2: self.remCache.reminders.nuiItems,
            width1:self.leftcols,
            width2:self.rightcols)
	    print("\u{251C}" + leftcolborder + "\u{253C}" + rightcolborder + "\u{2524}")
	    self.list_reminders_side_by_side(
            list1: self.remCache.reminders.uniItems,
            list2:self.remCache.reminders.nuniItems,
            width1:self.leftcols,
            width2:self.rightcols)
	    print("\u{2570}" + leftcolborder + "\u{2534}" + rightcolborder + "\u{256F}")

    }
}
