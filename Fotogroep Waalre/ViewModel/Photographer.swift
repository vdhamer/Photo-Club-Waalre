//
//  Photographer.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 03/07/2021.
//

import CoreData // needed for NSSet

extension Photographer: Comparable {

	public static func < (lhs: Photographer, rhs: Photographer) -> Bool {
		return (lhs.fullName < rhs.fullName)
	}

}

extension Photographer {

	var memberships: Set<MemberPortfolio> {
		get { (memberships_ as? Set<MemberPortfolio>) ?? [] }
		set { memberships_ = newValue as NSSet }
	}

	private(set) var givenName: String {
		get { return givenName_ ?? "MissingGivenName" }
		set { givenName_ = newValue }
	}

	private(set) var familyName: String {
		get { return familyName_ ?? "MissingFamilyName" }
		set { familyName_ = newValue }
	}

    var fullName: String {
        return givenName + " " + familyName
    }

    var memberRolesAndStatus: MemberRolesAndStatus {
        get { // conversion from Bool to dictionary
            return MemberRolesAndStatus(role: [:], stat: [
                .deceased: isDeceased]
            )
        }
        set { // merge newValue with existing dictionary
            if let newBool = newValue.stat[.deceased] {
                isDeceased = newBool!
            }
        }
    }

    var phoneNumber: String {
        get { return phoneNumber_ ?? ""}
        set { phoneNumber_ = newValue}
    }

    var eMail: String {
        get { return eMail_ ?? "" }
        set { eMail_ = newValue}
    }

    // Find existing object and otherwise create a new object
    // Update existing attributes or fill the new object
    static func findCreateUpdate(bgContext: NSManagedObjectContext, // check MOC TODO
                                 givenName: String, familyName: String,
                                 memberRolesAndStatus: MemberRolesAndStatus = MemberRolesAndStatus(role: [:],
                                                                                                   stat: [:]),
                                 phoneNumber: String? = nil, eMail: String? = nil,
                                 photographerWebsite: URL? = nil, bornDT: Date? = nil,
                                 photoClub: PhotoClub? = nil) -> Photographer { // photoClub only shown on console
        let predicateFormat: String = "givenName_ = %@ AND familyName_ = %@" // avoid localization
        let request = fetchRequest(predicate: NSPredicate(format: predicateFormat, givenName, familyName))

        let photographers: [Photographer] = (try? bgContext.fetch(request)) ?? [] // nil means absolute failure
        let photoClubPref = "\(photoClub?.fullNameTown ?? "No photo club provided"):"

        if let photographer = photographers.first {
            // already exists, so make sure secondary attributes are up to date
            let wasUpdated = update(bgContext: bgContext, photographer: photographer,
                                    memberRolesAndStatus: memberRolesAndStatus,
                                    phoneNumber: phoneNumber, eMail: eMail,
                                    photographerWebsite: photographerWebsite, bornDT: bornDT)
            if wasUpdated {
                print("\(photoClubPref) Updated info for photographer <\(photographer.fullName)>")
            } else {
                print("\(photoClubPref) No changes for photographer <\(photographer.fullName)>")
            }
            return photographer
        } else {
            // doesn't exist yet, so add new photographer
            let entity = NSEntityDescription.entity(forEntityName: "Photographer", in: bgContext)!
            let photographer = Photographer(entity: entity, insertInto: bgContext) // background: use special .init()
            photographer.givenName = givenName
            photographer.familyName = familyName
            _ = update(bgContext: bgContext, photographer: photographer, // TODO - check MOC
                       memberRolesAndStatus: memberRolesAndStatus,
                       phoneNumber: phoneNumber, eMail: eMail,
                       photographerWebsite: photographerWebsite, bornDT: bornDT)
            print("\(photoClubPref) Successfully created new photographer <\(photographer.fullName)>") // ignore updated
            return photographer
        }
    }

	// Update non-identifying properties within existing instance of class Photographer
    // Returns whether any of the non-identifying properties were updated.
    static func update(bgContext: NSManagedObjectContext, photographer: Photographer, // TODO - check MOC
                       memberRolesAndStatus: MemberRolesAndStatus,
                       phoneNumber: String? = nil, eMail: String? = nil,
                       photographerWebsite: URL? = nil, bornDT: Date? = nil) -> Bool {

		var wasUpdated: Bool = false

        if let isDeceased = memberRolesAndStatus.stat[.deceased], photographer.isDeceased != isDeceased {
            photographer.memberRolesAndStatus.stat[.deceased] = isDeceased
            wasUpdated = true
		}

        if let bornDT, photographer.bornDT != bornDT {
			photographer.bornDT = bornDT
            wasUpdated = true
		}

        if let phoneNumber, photographer.phoneNumber != phoneNumber {
            photographer.phoneNumber = phoneNumber
            wasUpdated = true
        }

        if let eMail, photographer.eMail != eMail {
            photographer.eMail = eMail
            wasUpdated = true
        }

        if let photographerWebsite, photographer.photographerWebsite != photographerWebsite {
            photographer.photographerWebsite = photographerWebsite
            wasUpdated = true
        }

		if wasUpdated {
			do {
				try bgContext.save()
			} catch {
                ifDebugFatalError("Update failed for photographer <\(photographer.fullName)>",
                                  file: #fileID, line: #line) // likely deprecation of #fileID in Swift 6.0
                // in release mode, if the data cannot be saved, log this and continue.
                wasUpdated = false
			}
		}
        return wasUpdated
	}

}

extension Photographer { // convenience function

	static func fetchRequest(predicate: NSPredicate) -> NSFetchRequest<Photographer> {
		let request = NSFetchRequest<Photographer>(entityName: "Photographer")
		request.predicate = predicate // WHERE part of the SQL query
		request.sortDescriptors = [NSSortDescriptor(key: "givenName_", ascending: true),
								   NSSortDescriptor(key: "familyName_", ascending: true)]
		return request
	}

}
