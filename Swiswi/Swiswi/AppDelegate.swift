//
//  AppDelegate.swift
//  Swiswi
//
//  Created by hideya kawahara on 2015/07/04.
//  Copyright (c) 2015年 hideya kawahara. All rights reserved.
//

import Cocoa
import Carbon

let udkSwitchInterval = "Switch Interval"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var statusMenuFirst: NSMenuItem!
    @IBOutlet weak var statusMenuFirstView: NSBox!
    @IBOutlet weak var intervalSlider: NSSlider!
    @IBOutlet weak var imageViewInAboutPanel: NSImageView!

    private var enabled : Bool = true
    private var switchInterval : Double = 0.0
    private var prevEventTimestamp : NSTimeInterval = 0
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)

    func applicationDidFinishLaunching(aNotification: NSNotification) {

        initStatusMenu()
        initAboutWindow()

        switchInterval = defaults.doubleForKey(udkSwitchInterval)
        if switchInterval == 0.0 {
            switchInterval = 0.35
            defaults.setDouble(switchInterval, forKey: udkSwitchInterval)
        }
        intervalSlider.doubleValue = switchInterval
        print(switchInterval)

        let desktopWindowNumber = getDesktopWindowNumber()
        let mainScreenHeight = NSScreen.mainScreen()!.frame.size.height
        let statusBarHeight = NSStatusBar.systemStatusBar().thickness
        let statusBarBottomY = mainScreenHeight - statusBarHeight
        var prevTabSwitching = false;

        NSEvent.addGlobalMonitorForEventsMatchingMask(.ScrollWheelMask) { event in

            if !self.enabled {
                return
            }

            if event.locationInWindow.y < statusBarBottomY && event.windowNumber != desktopWindowNumber {
                return
            }

            if abs(event.scrollingDeltaX) < 0.9 && abs(event.scrollingDeltaY) < 0.9 {
                return
            }

            if abs(event.scrollingDeltaX) > 0 && abs(event.scrollingDeltaY) > 0 {
                let angle = abs(event.scrollingDeltaY / event.scrollingDeltaX)
                if (0.5 < angle && angle < 2.0) {
                    return
                }
            }

            let tabSwitching = abs(event.scrollingDeltaY) < abs(event.scrollingDeltaX)
            let switchIntervalFactor = (tabSwitching == prevTabSwitching) ? 1.0 : 2.0

            if event.timestamp - self.prevEventTimestamp < self.switchInterval * switchIntervalFactor {
                return
            }
            self.prevEventTimestamp = event.timestamp

            prevTabSwitching = tabSwitching

            if tabSwitching {
                let windowLoopForwarad = (event.scrollingDeltaX > 0)
                if windowLoopForwarad {
                    self.postKeyDownAndUpEvents(CGKeyCode(kVK_ANSI_RightBracket), command: true, control: false, shift: true)
                } else {
                    self.postKeyDownAndUpEvents(CGKeyCode(kVK_ANSI_LeftBracket), command: true, control: false, shift: true)
                }
            } else {
                let windowLoopForwarad = (event.scrollingDeltaY > 0)
                self.postKeyDownAndUpEvents(CGKeyCode(kVK_F4), command: false, control: true, shift: !windowLoopForwarad)
            }
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    private func getDesktopWindowNumber() -> Int {
        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.OptionOnScreenOnly)
        let infoList = CGWindowListCopyWindowInfo(options, CGWindowID(0))

        for winDict in (infoList as NSArray? as? [[String: AnyObject]])! {
            let layer = winDict["kCGWindowLayer"] as! Int
            let winOwnerName = winDict["kCGWindowOwnerName"] as! NSString
            let winNumber =  winDict["kCGWindowNumber"] as! Int

            if layer < 0 && winOwnerName == "Finder" {
                return winNumber
            }
        }
        return 0
    }

    private func postKeyDownAndUpEvents(keyCode: CGKeyCode, command:Bool, control:Bool, shift:Bool) {
        // there should be a better way...
        let flags = CGEventFlags(rawValue:
            ((command ? CGEventFlags.MaskCommand.rawValue : 0) |
                (control ? CGEventFlags.MaskControl.rawValue : 0) |
                (shift ? CGEventFlags.MaskShift.rawValue : 0)))!

        let src = CGEventSourceCreate(CGEventSourceStateID.HIDSystemState)
        let keyDownEvent = CGEventCreateKeyboardEvent(src, keyCode, true)
        let keyUpEvent = CGEventCreateKeyboardEvent(src, keyCode, false)

        CGEventSetFlags(keyDownEvent, flags)
        CGEventSetFlags(keyUpEvent, flags)
        
        let location = CGEventTapLocation.CGHIDEventTap
        CGEventPost(location, keyDownEvent)
        CGEventPost(location, keyUpEvent)
    }

    private func initStatusMenu() {
        statusItem.image = NSImage(named: "StatusBarIcon")
        statusItem.menu = self.statusMenu
        statusMenuFirst.view = self.statusMenuFirstView
    }

    private func initAboutWindow() {
        window.orderOut(self)
        if #available(OSX 10.10, *) {
            window.titlebarAppearsTransparent = true
        } else {
            // Fallback on earlier versions
        }
        window.movableByWindowBackground  = true
        imageViewInAboutPanel.image = NSImage(named: "AppIcon")
    }

    @IBAction func sliderChanged(sender: AnyObject) {
        let value = sender.doubleValue
        print(value)
        switchInterval = value
        self.defaults.setDouble(switchInterval, forKey: udkSwitchInterval)
    }

    @IBAction func checkChanged(sender: AnyObject) {
        let value = sender.intValue
        self.enabled = (value > 0)
        self.intervalSlider.enabled = (value > 0)
        print(value)
    }

    @IBAction func infoButtonPressed(sender: AnyObject) {
        let frameRelativeToWindow = self.statusMenuFirst.view!.convertRect(self.statusMenuFirst.view!.bounds, toView: nil)
        let xRelativeToScreen = self.statusMenuFirst.view!.window!.convertRectToScreen(frameRelativeToWindow).origin.x
        let mainScreenHeight = NSScreen.mainScreen()!.frame.size.height
        let infoWindowWidth = window.frame.size.width
        window.setFrameOrigin(CGPoint(x: xRelativeToScreen - infoWindowWidth - 10, y: mainScreenHeight))
        NSApp.activateIgnoringOtherApps(true)
        window.makeKeyAndOrderFront(self)
    }

    @IBAction func showMoreInfo(sender: AnyObject) {
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: "http://hideya.github.io/swiswi/")!)
        window.close()
    }

    @IBAction func quitButtonPressed(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }
}
