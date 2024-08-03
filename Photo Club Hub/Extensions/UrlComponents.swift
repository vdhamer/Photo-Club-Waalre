//
//  UrlComponents.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 13/07/2024.
//

struct UrlComponents {

    let dataSourcePath: String
         // https://raw.githubusercontent.com/vdhamer/Photo-Club-Hub/main/hoto%20Club%20Hub/ViewModel/Lists/
    let dataSourceFile: String // fgDeGender
    let fileSubType: String // level2 (part of name)
    let fileType: String // json (actual file system type)

    var fullURLstring: String {
        // https://raw.githubusercontent.com/vdhamer/Photo-Club-Hub/main/ +
        // Photo%20Club%20Hub/ViewModel/Lists/fgDeGender.level2.json
        return dataSourcePath+dataSourceFile+"."+fileSubType+"."+fileType
    }

    var shortName: String {
        // fgDeGender.level2.json
        return dataSourceFile+"."+fileSubType+"."+fileType
    }

    // MARK: - Fotogroep de Gender

    static let deGender = UrlComponents(
        dataSourcePath: """
                        https://raw.githubusercontent.com/\
                        vdhamer/Photo-Club-Hub/\
                        main/\
                        Photo%20Club%20Hub/ViewModel/Lists/
                        """,
        dataSourceFile: "fgDeGender",
        fileSubType: "level2",
        fileType: "json"
    )

    // MARK: - Fotogroep Anders

    static let anders = UrlComponents(
        dataSourcePath: """
                        https://raw.githubusercontent.com/\
                        vdhamer/Photo-Club-Hub/\
                        main/\
                        Photo%20Club%20Hub/ViewModel/Lists/
                        """,
        dataSourceFile: "fgAnders",
        fileSubType: "level2",
        fileType: "json"
    )

    // MARK: - Bellus Imago

    static let bellusImago = UrlComponents(
        dataSourcePath: """
                        https://raw.githubusercontent.com/\
                        vdhamer/Photo-Club-Hub/\
                        main/\
                        Photo%20Club%20Hub/ViewModel/Lists/
                        """,
        dataSourceFile: "fcBellusImago",
        fileSubType: "level2",
        fileType: "json"
    )

    // MARK: - Waalre

    static let waalre = UrlComponents(
        dataSourcePath: """
                        https://raw.githubusercontent.com/\
                        vdhamer/Photo-Club-Hub/\
                        main/\
                        Photo%20Club%20Hub/ViewModel/Lists/
                        """,
        dataSourceFile: "fgWaalre",
        fileSubType: "level2",
        fileType: "json"
    )

}
