import EventKit
import Darwin


public class EisenhowerConsoleView {
	var cols: Int           // total columns we have to work with.
	var leftcols:  Int      // final width of the left column (considering lengths of all left items)
	var rightcols: Int      // final width of the right column
    
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
        } else {
            self.cols = 80
        }
        self.leftcols = Int(Double(self.cols) * 0.5)
		self.rightcols = Int(self.cols) - self.leftcols
        self.remCache = reminders
	}

    /**
     Build the text for a single reminder, including padding
     
     Made up of 4 fields:
        1. check box if completed
        2. a 3 digit hex hash
        3. a 0-9 digit for priority (see priority_map above)
        4. the reminder text (aka title)

     e.g. " ✔  A43 8 Eat Breakfast           "
     */
    func format(rem: EKReminder, width: Int) -> String {
        let checkColor = 120
        let hashColor  = 210

        let completed: String = rem.isCompleted ? "\u{1B}[38;5;\(checkColor)m✔\u{1B}[m" : " "   // colored check box
        
        let hash = "\u{1B}[38;5;\(hashColor)m\(rem.key)\u{1B}[m"                                // colored hash hex
        
        let priority = String(rem.priority)
        
        let titleColor: Int = rem.isCompleted ? 238 : 255                                       // color of reminder title text
        let titleText = (rem.title + String(repeating: " ", count: width)).prefix(width-6)
        let title = "\u{1B}[38;5;\(titleColor)m\(titleText)\u{1B}[m"
        
        return "\(completed)  \(hash) \(priority) \(title)"
    }
    
    /**
     Order reminders grouped by completion (uncompleted first, then completed)
     and ordered by priority (highest to lowest) within each group
     */
    func sortByCompletionAndPriority(r1: EKReminder, r2: EKReminder) -> Bool {
        if r1.isCompleted == r2.isCompleted {   // if both are complete or incomplete...
            return r1.priority < r2.priority    // then order by priority
        } else {
            return r2.isCompleted               // else order the incomplete one first
        }
    }

	/**
     Print one half of the table (top or bottom)
     This just takes care of the reminder lines themselves.   The horizontal dividers
     are printed directly in display()
     
     TODO:  clean up all the "magic numbers" in this func.
     */
    func list_reminders_side_by_side(list1: ReminderDict, list2: ReminderDict, width1: Int, width2: Int) {
        let rowCount = max(list1.count, list2.count)
        let sortedList1 = list1.values.sorted(by: sortByCompletionAndPriority)
        let sortedList2 = list2.values.sorted(by: sortByCompletionAndPriority)
        
        for row in 0..<rowCount {
            // Figure out what to print on the left side (either spaces or a reminder)
            var left: String  = String(repeating: " ", count: width1 - 4)     // Assume no item to print on the left (i.e. just print spaces)
            if row < sortedList1.count {                                      // but, if there _is_ an item,
                left =  self.format(rem: sortedList1[row], width: width1 - 7) // print it instead.
            }
            // Figure out what to print on the right side
            var right: String = String(repeating: " ", count: width2 - 3)     // Same for the text on the right
            if row < sortedList2.count {
                right = self.format(rem: sortedList2[row], width: width2 - 6)
            }
            // print left and right separated by vertical bars
            print("\u{2502} \(left) \u{2502} \(right) \u{2502}")
        }
    }

    // Given the four separate lists, dump them to the console.
	func display() {
        // Use box drawing characters to make a prettier border around the lists.
        // see https://en.wikipedia.org/wiki/Box-drawing_character
        leftcols  = max(leftMaxWidth,  leftcols)
        rightcols = max(rightMaxWidth, rightcols)

        if self.leftMaxWidth + self.rightMaxWidth <= self.cols {
            self.leftcols = self.leftMaxWidth
            self.rightcols = self.rightMaxWidth
       }
        
        let leftcolborder  = String(repeating: "\u{2500}", count: self.leftcols  - 2)
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
