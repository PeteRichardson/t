import EventKit

do {
	var view = EisenhowerConsoleView()

    var remCache = ReminderCache()
    
    var args = CommandLine.arguments
    args.remove(at:0)
    if args.count > 0 {
        switch (args[0]).lowercased() {
	        case "c":
	            args.remove(at: 0)
	            try remCache.complete_reminder(args: args)
	        case "d":
	            args.remove(at: 0)
	            try remCache.delete_reminder(args: args)
	        case "uih":
	            args.remove(at: 0)
	            remCache.add_reminder(args: args, priority: 1)
	        case "ui":
	            args.remove(at: 0)
	            remCache.add_reminder(args: args, priority: 2)
	        case "uil":
	            args.remove(at: 0)
	            remCache.add_reminder(args: args, priority: 3)
	        case "nuih":
	            args.remove(at: 0)
	            remCache.add_reminder(args: args, priority: 4)
	        case "nui":
	            args.remove(at: 0)
	            remCache.add_reminder(args: args, priority: 5)
	        case "nuil":
	            args.remove(at: 0)
	            remCache.add_reminder(args: args, priority: 6)
	        case "m":
	            args.remove(at: 0)
	            remCache.move_reminder(args: args)
	        case "unih":
	            args.remove(at: 0)
	            remCache.add_reminder(args: args, priority: 7)
	        case "uni":
	            args.remove(at: 0)
	            remCache.add_reminder(args: args, priority: 8)
	        case "unil":
	            args.remove(at: 0)
	            remCache.add_reminder(args: args, priority: 9)
	        case "nuni":
	            args.remove(at: 0)
	            remCache.add_reminder(args: args, priority: 0)
	        default:
	            remCache.add_reminder(args: args, priority: 0)
        }
    }
    remCache.loadItems()
    view.display(uiItems: remCache.uiItems, nuiItems: remCache.nuiItems, uniItems:remCache.uniItems, nuniItems: remCache.nuniItems, leftMaxWidth: remCache.leftMaxWidth, rightMaxWidth: remCache.rightMaxWidth)

} catch {
    print("Something is wrong")
}
