import EventKit
import Cncurses
import Darwin.ncurses

do {
	initscr()
	var cols:Int = Int(COLS)
	var leftcols:Int = Int(Double(COLS) * 0.5) - 4
	var rightcols:Int = Int(COLS) - leftcols
	endwin()
    
    var remCache = ReminderCache()
    
    var args = Process.arguments
    args.removeAtIndex(0)
    if args.count > 0 {
        switch (args[0]).lowercaseString {
	        case "c":
	            args.removeAtIndex(0)
	            try remCache.complete_reminder(args)
	        case "d":
	            args.removeAtIndex(0)
	            try remCache.delete_reminder(args)
	        case "ui":
	            args.removeAtIndex(0)
	            remCache.add_reminder(args, priority: 1)
	        case "nui":
	            args.removeAtIndex(0)
	            remCache.add_reminder(args, priority: 5)
	        case "uni":
	            args.removeAtIndex(0)
	            remCache.add_reminder(args, priority: 9)
	        case "nuni":
	            args.removeAtIndex(0)
	            remCache.add_reminder(args, priority: 0)
	        default:
	            remCache.add_reminder(args, priority: 0)
        }
    }

    let separator : String = String(count: cols-1,repeatedValue: Character("-"))
    print(separator)
    remCache.list_reminders_side_by_side(remCache.uiItems, list2:remCache.nuiItems, width1:leftcols, width2:rightcols)
    print(separator)
    remCache.list_reminders_side_by_side(remCache.uniItems, list2:remCache.nuniItems, width1:leftcols, width2:rightcols)
    print(separator)
} catch {
    print("Something is wrong")
}
