//
//  TestClubMembersProvider+insertSomeHardcodedMemberData.swift
//  Fotogroep Waalre
//
//  Created by Peter van den Hamer on 01/08/2021.
//

import CoreData // for NSManagedObjectContext
import MapKit // for CLLocationCoordinate2D

extension TestClubMembersProvider { // fill with some initial hard-coded content

    private static let testURL = URL(string: "https://www.nederlandsfotomuseum.nl")
    static let photoClubTestID = PhotoClubID(id: (fullName: "Test Fotoclub", // identical name to club in Amsterdam
                                                  town: "Rotterdam"),
                                             shortNickname: "FC Test")

    func insertSomeHardcodedMemberData(testBackgroundContext: NSManagedObjectContext) {
        testBackgroundContext.perform {
            print("Photo Club Test: starting insertSomeHardcodedMemberData() in background")
            self.insertSomeHardcodedMemberDataCommon(testBackgroundContext: testBackgroundContext, commit: true)
        }
    }

    private func insertSomeHardcodedMemberDataCommon(testBackgroundContext: NSManagedObjectContext,
                                                     commit: Bool) {

        // add photo club to Photo Clubs (if needed)
        let clubTest = PhotoClub.findCreateUpdate(
                                                         context: testBackgroundContext,
                                                         photoClubID: Self.photoClubTestID,
                                                         photoClubWebsite: TestClubMembersProvider.testURL,
                                                         fotobondNumber: 1234, kvkNumber: nil,
                                                         coordinates: CLLocationCoordinate2D(latitude: 51.905292,
                                                                                             longitude: 4.486934),
                                                         priority: 1
                                                        )

        addMember(context: testBackgroundContext,
                  givenName: "Peter",
                  familyName: "van den Hamer",
                  photoClub: clubTest,
                  memberRolesAndStatus: MemberRolesAndStatus(role: [ .admin: true ], stat: [ .former: false]),
                  memberWebsite: URL(string: "https://www.fotogroepwaalre.nl/fotos/Peter_van_den_Hamer_test")!,
                  latestImage: URL(string:
                     "https://www.fotogroepwaalre.nl/fotos/Peter_van_den_Hamer_test/" +
		                                    "images/2015_Madeira_RX1r_064.jpg")!,
                  phoneNumber: nil,
                  eMail: "foobar@vdhamer.com"
        )

        if commit {
            do {
                if testBackgroundContext.hasChanges {
                    try testBackgroundContext.save() // commit all changes
                }
                print("Photo Club Test: completed insertSomeHardcodedMemberData()")
            } catch {
                fatalError("Failed to save changes for Test")
            }
        }

    }

    private func addMember(context: NSManagedObjectContext,
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
                            context: context, givenName: givenName, familyName: familyName,
                            memberRolesAndStatus: memberRolesAndStatus,
                            bornDT: bornDT )

        _ = MemberPortfolio.findCreateUpdate(
                            context: context, photoClub: photoClub, photographer: photographer,
                            memberRolesAndStatus: memberRolesAndStatus,
                            memberWebsite: memberWebsite,
                            latestImage: latestImage)
    }

}
