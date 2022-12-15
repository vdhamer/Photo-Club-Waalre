//
//  View+Navigate.swift
//  Fotogroep Waalre
//
//  Created by Peter van den Hamer on 05/03/2022.
//

import SwiftUI

extension View {
    /// Navigate to a new view.
    /// - Parameters:
    ///   - view: View to navigate to.
    ///   - binding: Only navigates when this condition is `true`.
    func navigate<NewView: View>(to view: NewView,
                                 when binding: Binding<Bool>,
                                 enableBack: Bool = determineEnableBack()) // for testing
                                 -> some View {
        NavigationStack {
            NavigationLink(value: 0) { /// `value` is not used
                self // tapping this sets off the link
                    .navigationBarHidden(true)
            }
            .navigationDestination(isPresented: binding) {
                view
                    .navigationBarBackButtonHidden(enableBack == false)
            }
        }
    }

    static func determineEnableBack() -> Bool {
        if UIDevice.isIPad {
            return true
        }
        return false
    }
}
