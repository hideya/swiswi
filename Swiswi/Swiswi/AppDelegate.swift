//
//  AppDelegate.swift
//  Swiswi
//
//  Created by hideya kawahara on 2015/07/04.
//  Copyright (c) 2015年 hideya kawahara. All rights reserved.
//

import Cocoa

let udkSwitchInterval = "Switch Interval";

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var statusMenuFirst: NSMenuItem!
    @IBOutlet weak var statusMenuFirstView: NSBox!
    @IBOutlet weak var intervalSlider: NSSlider!
    @IBOutlet weak var imageViewInAboutPanel: NSImageView!

    var enabled : Bool = true;
    var switchInterval : Double = 0.0;
    var prevEventTimestamp : NSTimeInterval = 0;
    let defaults = NSUserDefaults.standardUserDefaults()
    let statusItem: NSStatusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)

    func applicationDidFinishLaunching(aNotification: NSNotification) {

        initStatusMenu()
        initAboutWindow()

        switchInterval = defaults.doubleForKey(udkSwitchInterval)
        if switchInterval == 0.0 {
            switchInterval = 0.35
            defaults.setDouble(switchInterval, forKey: udkSwitchInterval)
        }
        intervalSlider.doubleValue = switchInterval
        println(switchInterval);

        var desktopWindowNumber = getDesktopWindowNumber();

        NSEvent.addGlobalMonitorForEventsMatchingMask(.ScrollWheelMask, handler: { event in

            if !self.enabled {
                return
            }

            let shiftKeyPressed = event.modifierFlags.isSet(.ShiftKeyMask)
            let ctrlKeyPressed = event.modifierFlags.isSet(.ControlKeyMask)
            var mainScreenHeight = NSScreen.mainScreen()!.frame.size.height
            var statusBarHeight = NSStatusBar.systemStatusBar().thickness
            var statusBarBottomY = mainScreenHeight - statusBarHeight;

            if event.locationInWindow.y < statusBarBottomY && event.windowNumber != desktopWindowNumber {
                return;
            }

            if abs(event.scrollingDeltaY) < abs(event.scrollingDeltaX) {
                return;
            }

            if abs(event.scrollingDeltaY) < 0.9 { // trackpad can generate a delta == 0.0f
                return;
            }

            if event.hasPreciseScrollingDeltas { // if this event is generated by a trackpad
                if event.timestamp - self.prevEventTimestamp < self.switchInterval {
                    return;
                }
            }
            self.prevEventTimestamp = event.timestamp;

            var windowLoopForwarad = (event.scrollingDeltaY > 0);

            if ctrlKeyPressed || shiftKeyPressed {
                postKeyboardEvent(0x30/*kVK_Tab*/, true, true, !windowLoopForwarad);
                postKeyboardEvent(0x30/*kVK_Tab*/, false, true, !windowLoopForwarad);
            } else {
                postKeyboardEvent(0x76/*kVK_F4*/, true, true, !windowLoopForwarad);
                postKeyboardEvent(0x76/*kVK_F4*/, false, true, !windowLoopForwarad);
            }

        })
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func initStatusMenu() {
        statusItem.image = NSImage(named: "StatusBarIcon")
        statusItem.menu = self.statusMenu
        statusMenuFirst.view = self.statusMenuFirstView
    }

    func initAboutWindow() {
//        window.orderOut(self)
        window.titlebarAppearsTransparent = true
        window.movableByWindowBackground  = true
        imageViewInAboutPanel.image = NSImage(named: "AppIcon")
    }

    @IBAction func sliderChanged(sender: AnyObject) {
        var value = sender.doubleValue
        println(value);
        switchInterval = value;
        self.defaults.setDouble(switchInterval, forKey: udkSwitchInterval)
    }

    @IBAction func checkChanged(sender: AnyObject) {
        var value = sender.intValue
        self.enabled = (value > 0)
        self.intervalSlider.enabled = (value > 0)
        println(value);
    }

    @IBAction func infoButtonPressed(sender: AnyObject) {
//        var frameRelativeToWindow = self.statusMenuFirst.view!.convertRect(self.statusMenuFirst.view!.bounds, toView: nil)
//        var pointRelativeToScreen = self.statusMenuFirst.view!.window!.convertRectToScreen(frameRelativeToWindow).origin.x;
//        NSLog("*** %d", pointRelativeToScreen)

        var mainScreenHeight = NSScreen.mainScreen()!.frame.size.height
        var mainScreenWidth = NSScreen.mainScreen()!.frame.size.width
        var infoWindowWidth = window.frame.size.width
        var frame = window.frame
        frame.origin = CGPoint(x: mainScreenWidth / 2 - infoWindowWidth / 2, y: mainScreenHeight)
        NSApp.activateIgnoringOtherApps(true)
        window.setFrame(frame, display: true)
        window.makeKeyAndOrderFront(self)
    }

    @IBAction func quitButtonPressed(sender: AnyObject) {
        exit(0)
    }
}

func getDesktopWindowNumber() -> Int {
    var desktopWindowNumber = 0;
    let options = CGWindowListOption(kCGWindowListOptionOnScreenOnly)
    let cfInfoList = CGWindowListCopyWindowInfo(options, CGWindowID(0)).takeRetainedValue()

    for winDict in cfInfoList as! [NSDictionary] {
        var layer = winDict["kCGWindowLayer"] as! Int
        var winOwnerName = winDict["kCGWindowOwnerName"] as! NSString

        if layer < 0 && winOwnerName == "Finder" {
            desktopWindowNumber = winDict["kCGWindowNumber"] as! Int
        }
    }
    return desktopWindowNumber;
}

func postKeyboardEvent(keyCode: CGKeyCode, keyDown:Bool, controlKeyDown:Bool, shiftKeyDown:Bool) {
    let src = CGEventSourceCreate(CGEventSourceStateID(kCGEventSourceStateHIDSystemState)).takeRetainedValue()
    let keyEvent = CGEventCreateKeyboardEvent(src, keyCode, keyDown).takeRetainedValue()
    if controlKeyDown {
        CGEventSetFlags(keyEvent, CGEventFlags(kCGEventFlagMaskControl));
    }
    if shiftKeyDown {
        CGEventSetFlags(keyEvent, CGEventFlags(kCGEventFlagMaskShift));
    }
    if controlKeyDown && shiftKeyDown {
        CGEventSetFlags(keyEvent, CGEventFlags(kCGEventFlagMaskControl | kCGEventFlagMaskShift));
    }

    let location = CGEventTapLocation(kCGHIDEventTap)

    CGEventPost(location, keyEvent);
}

extension NSEventModifierFlags {

    func isSet(bit: NSEventModifierFlags) -> Bool {
        return self & bit == bit
    }

}

