//
//  FotogroepWaalreMembersProvider.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 17/07/2021.
//

import CoreData // for NSManagedObjectContext
import RegexBuilder // for Regex struct

class FotogroepWaalreMembersProvider { // WWDC21 Earthquakes also uses a Class here

    static let photoClubWaalreIdPlus = PhotoClubIdPlus(fullName: "Fotogroep Waalre",
                                                       town: "Waalre",
                                                       nickname: "FG Waalre")

    init(bgContext: NSManagedObjectContext) {
        // following is asynchronous, but not documented as such using async/await
        bgContext.perform { // done asynchronously by CoreData
            self.insertSomeHardcodedMemberData(bgContext: bgContext)
//            self.insertOnlineMemberData(bgContext: bgContext)
        }
    }

}

extension FotogroepWaalreMembersProvider { // private utitity functions

    func isStillAlive(phone: String?) -> Bool {
        return phone != "[overleden]"
    }

    func isCurrentMember(name: String, includeCandidates: Bool) -> Bool {
        // "Guido Steger" -> false
        // "Bart van Stekelenburg (lid)" -> true
        // "Zoë Aspirant (aspirantlid)" -> depends on includeCandidates param
        // "Hans Zoete (mentor)" -> false
        let regex = Regex {
            ZeroOrMore(.any)
            OneOrMore(.horizontalWhitespace)
            Capture {
                ChoiceOf {
                    "(lid)" // NL
                    "(member)" // not via localization because input file can have different language setting than app
                }
            }
        }

        if (try? regex.wholeMatch(in: name)) != nil {
            return true
        } else if !includeCandidates {
            return false
        } else {
            return isProspectiveMember(name: name)
        }
    }

    func isMentor(name: String) -> Bool {
        // "Guido Steger" -> false
        // "Bart van Stekelenburg (lid)" -> false
        // "Zoë Aspirant (aspirantlid)" -> false
        // "Hans Zoete (mentor)" -> true
        let regex = Regex {
            ZeroOrMore(.any)
            OneOrMore(.horizontalWhitespace)
            Capture {
                ChoiceOf {
                    "(mentor)" // NL
                    "(coach)" // EN
                }
            }
        }

        if (try? regex.wholeMatch(in: name)) != nil {
            return true
        } else {
            return false
        }
    }

    func isProspectiveMember(name: String) -> Bool {
        // "Bart van Stekelenburg (lid)" -> false
        // "Zoë Aspirant (aspirantlid)" -> true
        // "Guido Steger" -> false
        // "Hans Zoete (mentor)" -> false
        let regex = Regex {
            ZeroOrMore(.any)
            OneOrMore(.horizontalWhitespace)
            Capture {
                ChoiceOf {
                    "(aspirantlid)" // NL
                    "(aspiring)" // EN
                }
            }
        }

        if (try? regex.wholeMatch(in: name)) != nil {
            return true
        } else {
            return false
        }
    }

}
