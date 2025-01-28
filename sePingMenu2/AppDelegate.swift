import Cocoa
import Network

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var timer: Timer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Application did finish launching!")
        
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "Ping..."
        if let button = statusItem?.button {
            button.font = NSFont.systemFont(ofSize: 10)  // Smaller than default ~13
        }
        statusItem = NSStatusBar.system.statusItem(withLength: 23.0)
        statusItem?.button?.alignment = .right

        
        // Create a timer to update ping every second
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(updatePing),
                                     userInfo: nil,
                                     repeats: true)
        
        // Create a menu for the status item (so we can quit)
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit",
                                action: #selector(handleQuit),
                                keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func handleQuit() {
        NSApp.terminate(nil)
    }

    @objc func updatePing() {
        measurePingAsync(to: "google.com") { [weak self] pingResult in
            
//            var roundedPingResult = pingResult
//            if pingResult >= 0 && pingResult <= 50 { roundedPingResult = 50
//            } else if pingResult <= 100 { roundedPingResult = 100
//            } else if pingResult <= 200 { roundedPingResult = 200
//            } else if pingResult <= 300 { roundedPingResult = 300
//            } else if pingResult <= 500 { roundedPingResult = 500
//            } else if pingResult <= 999 { roundedPingResult = 900
//            }

            // If -1, show x_x, otherwise show e.g. "27"
            let displayText = NSAttributedString(
                string: (pingResult == -1) ? "x_x" : "\(pingResult)",
                attributes: [
                    .foregroundColor: (pingResult == -1) ? NSColor.red : NSColor.labelColor
                ]
            )
            
            print("Ping result: \(displayText.string)")

            DispatchQueue.main.async {
                self?.statusItem?.button?.attributedTitle = displayText
            }
        }
    }
    
    /// Asynchronously measure "ping" time by establishing a TCP connection to port 80.
    /// Instead of blocking with a semaphore, we use a completion handler.
    func measurePingAsync(to host: String, completion: @escaping (Int) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let connection = NWConnection(host: NWEndpoint.Host(host), port: 80, using: .tcp)

        // We'll store a flag so we know if we already reported a result
        var didFinish = false

        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                // If we're ready before the timeout, compute the time
                if !didFinish {
                    didFinish = true

                    let endTime = CFAbsoluteTimeGetCurrent()
                    let elapsedMs = (endTime - startTime) * 1000
                    let pingValue = Int(elapsedMs)

                    print("[DEBUG] TCP connect to \(host) successful: \(pingValue) ms")

                    connection.cancel()
                    completion(pingValue)
                }
                
            case .failed(let error):
                // Could not connect
                if !didFinish {
                    didFinish = true
                    print("[DEBUG] TCP connect to \(host) failed: \(error)")
                    connection.cancel()
                    completion(-1)
                }
                
            default:
                // .setup, .waiting, .cancelled, etc.
                break
            }
        }

        // Start on a background queue
        connection.start(queue: .global(qos: .background))
        
        // 1-Second Timeout
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // If not finished by now, we assume it's too slow / no network
            if !didFinish {
                didFinish = true
                print("[DEBUG] TCP connect to \(host) timed out (>1s).")
                connection.cancel()
                completion(-1)
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        print("Application will terminate!")
        timer?.invalidate()
    }
}
