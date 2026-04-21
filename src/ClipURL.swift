import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURL(_:withReply:)),
            forEventClass: AEEventClass(0x4755524C), // 'GURL' kInternetEventClass
            andEventID:   AEEventID(0x4755524C)      // 'GURL' kAEGetURL
        )
    }

    @objc func handleURL(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        defer { NSApp.terminate(nil) }
        guard
            let urlString = event.paramDescriptor(forKeyword: AEKeyword(0x2D2D2D2D))?.stringValue,
            let url = URL(string: urlString),
            !url.path.isEmpty
        else { return }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/pbcopy")
        let pipe = Pipe()
        proc.standardInput = pipe
        try? proc.run()
        pipe.fileHandleForWriting.write(Data(url.path.utf8))
        pipe.fileHandleForWriting.closeFile()
        proc.waitUntilExit()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
