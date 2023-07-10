//
//  TestClubDenHaagMembersProvider+insertSomeHardcodedMemberData.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 11/01/2023.
//

import CoreData // for NSManagedObjectContext
import MapKit // for CLLocationCoordinate2D

extension TestClubDenHaagMembersProvider { // fill with some initial hard-coded content

    private static let testDenHaagURL = URL(string: "https://www.km21.nl")
    static let photoClubTestDenHaagIdPlus = PhotoClubIdPlus(fullName: "Test Fotoclub",
                                                              town: "Den Haag", // Rotterdam also has a "Test Fotoclub"
                                                              nickname: "FC Test DenHaag")

    func insertSomeHardcodedMemberData(bgContext: NSManagedObjectContext) {
        bgContext.perform {
            ifDebugPrint("Photo Club Test Adam: starting insertSomeHardcodedMemberData() in background")
            self.insertSomeHardcodedMemberDataCommon(bgContext: bgContext, commit: true)
        }
    }

    private func insertSomeHardcodedMemberDataCommon(bgContext: NSManagedObjectContext,
                                                     commit: Bool) {

        // add photo club to Photo Clubs (if needed)
        let clubTestDenHaag = PhotoClub.findCreateUpdate(
                                                 bgContext: bgContext,
                                                 photoClubIdPlus: Self.photoClubTestDenHaagIdPlus,
                                                 photoClubWebsite: Self.testDenHaagURL,
                                                 fotobondNumber: nil, kvkNumber: nil,
                                                 coordinates: CLLocationCoordinate2D(latitude: 52.090556,
                                                                                     longitude: 4.279722),
                                                 priority: 1
                                                )
        clubTestDenHaag.hasHardCodedMemberData = true // store in database that we ran insertSomeHardcodedMembers...

        addMember(bgContext: bgContext,
                  givenName: "Peter",
                  familyName: "van den Hamer",
                  photoClub: clubTestDenHaag,
                  memberRolesAndStatus: MemberRolesAndStatus(role: [ .viceChairman: true ], stat: [ .former: false]),
                  memberWebsite: URL(string: "https://www.fotogroepwaalre.nl/fotos/Peter_van_den_Hamer_testDH")!,
                  latestImage: URL(string:
                     "https://www.fotogroepwaalre.nl/fotos/Peter_van_den_Hamer_testDH/" +
                                                    "thumbs/2010_Barcelona_95.jpg")!,
                  eMail: "foobarDH@vdhamer.com"
        )

        if commit {
            do {
                if bgContext.hasChanges { // is this necessary? sometimes save() done earlier
                    try bgContext.save() // commit all changes
                }
                ifDebugPrint("Photo Club Test Den Haag: completed insertSomeHardcodedMemberData()")
            } catch {
                ifDebugFatalError("Failed to save changes for Test Den Haag",
                                  file: #fileID, line: #line) // likely deprecation of #fileID in Swift 6.0
                // in release mode, failing to store the data is only logged. And the app doesn't stop.
            }
        }

    }

    private func addMember(bgContext: NSManagedObjectContext,
                           givenName: String,
                           familyName: String,
                           bornDT: Date? = nil,
                           photoClub: PhotoClub,
                           memberRolesAndStatus: MemberRolesAndStatus = MemberRolesAndStatus(role: [:], stat: [:]),
                           memberWebsite: URL? = nil,
                           latestImage: URL? = nil,
                           phoneNumber: String? = nil,
                           eMail: String? = nil) {
        let photographer = Photographer.findCreateUpdate(
                            bgContext: bgContext, givenName: givenName, familyName: familyName, // TODO - check MOC
                            memberRolesAndStatus: memberRolesAndStatus,
                            bornDT: bornDT )

        _ = MemberPortfolio.findCreateUpdate(
                            bgContext: bgContext, photoClub: photoClub, photographer: photographer,
                            memberRolesAndStatus: memberRolesAndStatus,
                            memberWebsite: memberWebsite,
                            latestImage: latestImage)
    }

}
