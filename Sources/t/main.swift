import EventKit

let priority_map = [
	"uih":  1,
	"ui":   2,
	"uil":  3,
	"nuih": 4,
	"nui":  5,
	"nuil": 6,
	"unih": 7,
	"uni":  8,
	"unil": 9,
	"nuni": 0
]

do {
	let view = EisenhowerConsoleView()

    let remCache = ReminderCache()
    
    var args = CommandLine.arguments
    args.remove(at:0)
    if args.count > 0 {
    	let words = Array(args.suffix(args.count-1))
    	let command = args[0].lowercased()
        switch command {
	        case "c":
	            try remCache.complete_reminder(args: words)
	        case "d":
	            try remCache.delete_reminder(args: words)
	        case "m":
	            remCache.move_reminder(args: words)
	        case  "uih",  "ui",  "uil",
	        	 "nuih", "nui", "nuil",
	        	 "unih", "uni", "unil",
	        	 "nuni":
	            remCache.add_reminder(args: words, priority: priority_map[command]!)
	        default:
	            remCache.add_reminder(args: args, priority: 0)
        }
    }
    remCache.loadItems()
    
    view.display(uiItems: remCache.uiItems, nuiItems: remCache.nuiItems, uniItems:remCache.uniItems, nuniItems: remCache.nuniItems, leftMaxWidth: remCache.leftMaxWidth, rightMaxWidth: remCache.rightMaxWidth)

} catch {
    print("Something is wrong")
}
