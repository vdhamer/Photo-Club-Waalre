//
//  Settings.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 23/06/2024.
//

import Foundation

struct Settings {

    static var dataResetPending272: Bool { // stored as a string shown in Settings
        // returns true until a reset is done

        if UserDefaults.standard.object(forKey: "dataResetPending272") == nil {
            UserDefaults.standard.set(true, forKey: "dataResetPending272") // interpret nil as true
            UserDefaults.standard.removeObject(forKey: "dataResetPending") // cleanup of unused key-value pair
        }

        let prevValue = UserDefaults.standard.bool(forKey: "dataResetPending272")
        UserDefaults.standard.set(false, forKey: "dataResetPending272") // never true more than once
        return prevValue // if true, app has to react immediately (by executing data reset)
    } // implicit getter only

    static var manualDataLoading: Bool { // controlled by toggle in Settings
        // Setting this to true clears the existing database and skips loading any data on app startup.
        // It displays "Manual loading" in the Prelude startup screen as a warning that the mode is set.
        // The missing club/museum/member data can be loaded manually by swiping down on e.g., the Portfolio screen.
        get {
            UserDefaults.standard.bool(forKey: "manualDataLoading") // here we are happy with missing key -> false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "manualDataLoading")
        }
    }

    static var extraCoreDataSaves: Bool { // controlled by toggle in Settings
        // Important setting that should normally be kept false.
        // It adds extra ManagedObjectContext.save() transactions to the minimal set of save's.
        // It is needed for testing purposes only.
        get {
            UserDefaults.standard.bool(forKey: "extraCoreDataSaves") // here we are happy with missing key -> false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "extraCoreDataSaves")
        }
    }

}
