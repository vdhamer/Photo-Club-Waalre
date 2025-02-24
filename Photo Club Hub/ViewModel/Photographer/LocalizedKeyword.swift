//
//  LocalizedKeyword.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 23/02/2025.
//

import CoreData // for NSManagedObjectContext

extension LocalizedKeyword {

    // MARK: - getters (setting is done via findCreateUpdate)

    var keyword: Keyword { // getter
        if let keyword = keyword_ {
            return keyword
        } else {
            fatalError("Error because keyword is nil") // something is fundamentally wrong if this happens
        }
    }

    var language: Language { // getter
        if let language = language_ {
            return language
        } else {
            fatalError("Error because language is nil") // something is fundamentally wrong if this happens
        }
    }

    // MARK: - find or create

    // Find existing Keyword object or create a new one.
    // Update existing attributes or fill the new object
    static func findCreateUpdate(context: NSManagedObjectContext, // can be foreground of background context
                                 keyword: Keyword,
                                 language: Language,
                                 localizedName: String,
                                 localizedUsage: String?
                                ) -> LocalizedKeyword {

        let predicateFormat: String = "keyword_ = %@ AND language_ = %@" // avoid localization of query string
        let predicate = NSPredicate(format: predicateFormat, argumentArray: [keyword, language])
        let fetchRequest: NSFetchRequest<LocalizedKeyword> = LocalizedKeyword.fetchRequest()
        fetchRequest.predicate = predicate
        var localizedKeywords: [LocalizedKeyword]! = []
        do {
            localizedKeywords = try context.fetch(fetchRequest)
        } catch {
            ifDebugFatalError("Failed to fetch LocalizedKeyword for \(keyword.id) in \(language.isoCodeCaps): \(error)",
                              file: #fileID, line: #line)
            // on non-Debug version, continue with empty `keywords` array
        }

        // are there multiple translations of the keyword into the same language? This shouldn't be the case
        if localizedKeywords.count > 1 { // there is actually a Core Data constraint to prevent this
            ifDebugFatalError("""
                              Query returned multiple (\(localizedKeywords.count)) translations \
                              of Keyword \(keyword.id) into \(language.isoCodeCaps)
                              """,
                              file: #fileID, line: #line) // likely deprecation of #fileID in Swift 6.0
            // in release mode, log that there are multiple clubs, but continue using the first one.
        }

        // if a translation already exists, update non-identifying attributes
        if let localizedKeyword = localizedKeywords.first {
            if localizedKeyword.update(context: context, localizedName: localizedName, localizedUsage: localizedUsage) {
                print("""
                      Updated translation of keyword \"\(keyword.id)\" into \(language.isoCodeCaps) as \(localizedName)
                      """)
                if Settings.extraCoreDataSaves {
                    localizedKeyword.save(context: context)
                }
            }
            return localizedKeyword
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "LocalizedKeyword", in: context)!
            let localizedKeyword = LocalizedKeyword(entity: entity, insertInto: context)
            localizedKeyword.name = localizedName // immediately set it to a non-nil value
            localizedKeyword.keyword_ = keyword
            localizedKeyword.language_ = language
            _ = localizedKeyword.update(context: context, localizedName: localizedName, localizedUsage: localizedUsage)
            if Settings.extraCoreDataSaves {
                localizedKeyword.save(context: context)
            }
            return localizedKeyword
        }

     }

    // Update non-identifying attributes/properties within an existing instance of class LocalizedKeyword if needed.
    // Returns whether an update was needed.
    fileprivate func update(context: NSManagedObjectContext,
                            localizedName: String,
                            localizedUsage: String?) -> Bool {

        var modified: Bool = false

        if self.name != localizedName {
            self.name = localizedName
            modified = true
        }

        if let localizedUsage, self.usage != localizedUsage {
            self.usage = localizedUsage
            modified = true
        }

        if modified && Settings.extraCoreDataSaves {
            do {
                try context.save() // update modified properties of a Keyword object
             } catch {
                 ifDebugFatalError("""
                                   Update failed for LocalizedKeyword \
                                   (\(self.keyword.id) | \(self.language.isoCodeCaps))
                                   """,
                                  file: #fileID, line: #line) // likely deprecation of #fileID in Swift 6.0
                // in release mode, if save() fails, just continue
            }
        }

        return modified
    }

    // MARK: - utilities

    func save(context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                context.rollback()
                ifDebugFatalError("""
                                  Could not save LocalizedKeyword for \"\(self.keyword.id)\" \
                                  into \(self.language.isoCodeCaps)
                                  """)
            }
        }
    }

}
