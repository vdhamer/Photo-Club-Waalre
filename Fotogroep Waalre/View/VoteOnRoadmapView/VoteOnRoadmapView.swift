//
//  RoadmapView.swift
//  Fotogroep Waalre
//
//  Created by Peter van den Hamer on 05/03/2023.
//

import SwiftUI
import Roadmap

struct VoteOnRoadmapView: View {

    let configuration = RoadmapConfiguration(
                            // could use an external URL(string: "https://simplejsoncms.com/api/vnlg2fq62s")!,
                            roadmapJSONURL: Bundle.main.url(forResource: "Roadmap", withExtension: "json")!,
                            voter: CustomVoter(namespace: Bundle.main.bundleIdentifier!),
                            style: RoadmapStyle(icon: Image(systemName: "circle.square.fill"),
                                                titleFont: RoadmapTemplate.standard.style.titleFont.italic(),
                                                numberFont: RoadmapTemplate.standard.style.numberFont,
                                                statusFont: RoadmapTemplate.standard.style.statusFont,
                                                statusTintColor: lookupStatusTintColor, // closure
                                                cornerRadius: 10,
                                                cellColor: RoadmapTemplate.standard.style.cellColor, // cell background
                                                selectedColor: RoadmapTemplate.standard.style.selectedForegroundColor,
                                                tint: RoadmapTemplate.standard.style.tintColor), // voting icon
                            shuffledOrder: true,
                            allowVotes: true,
                            allowSearching: false)

    private let title = String(localized: "Roadmap Items", comment: "Title of Roadmap screen")
    private let buttonText = String(localized:
                              """
                              You can vote here on roadmap items that you would like to see. \
                              Please read the entire list before voting bacause you cannot undo a vote. \
                              Don't vote for more than half the items: the data helps us \
                              prioritize (this isn't about \"liking\" individual items).
                              """,
                              comment: "Text at top of Roadmap screen")

    var body: some View {
        NavigationStack {
            RoadmapView(configuration: configuration, header: {
                Text(buttonText)
                    .italic()
                    .font(.callout)
                    .foregroundColor(.blue)
            })
                .navigationTitle(title)
        }
    }

    static func lookupStatusTintColor(string: String) -> Color {
        switch string.localizedLowercase {
        case "planned": return .plannedColor
        case "?": return .unplannedColor
        default: return Color.secondary
        }
    }

}

// CustomVoter is a wrapper around the default voter used by the Roadmap package
private struct CustomVoter: FeatureVoter {

    private let defaultVoter: FeatureVoterCountAPI

    init(namespace: String) {
        defaultVoter = FeatureVoterCountAPI(namespace: namespace)
    }

    func fetch(for feature: Roadmap.RoadmapFeature) async -> Int {
        await defaultVoter.fetch(for: feature)
    }

    func vote(for feature: Roadmap.RoadmapFeature) async -> Int? {
        await defaultVoter.vote(for: feature)
    }

}

struct MyRoadmapView_Previews: PreviewProvider {
    @State static private var title = "MyRoadmapView_Preview"

    static var previews: some View {
        VoteOnRoadmapView()
            .navigationTitle(title)
    }
}
