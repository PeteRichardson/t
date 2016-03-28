import EventKit

do {
	var view = EisenhowerConsoleView()

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
	        case "m":
	            args.removeAtIndex(0)
	            remCache.move_reminder(args)
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

    view.display(remCache.uiItems, nuiItems: remCache.nuiItems, uniItems:remCache.uniItems, nuniItems: remCache.nuniItems, leftMaxWidth: remCache.leftMaxWidth, rightMaxWidth: remCache.rightMaxWidth)

} catch {
    print("Something is wrong")
}
