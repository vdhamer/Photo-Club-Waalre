//
//  PhotoClubs.swift
//  Fotogroep Waalre
//
//  Created by Peter van den Hamer on 30/12/2021.
//

import SwiftUI
import MapKit
import CoreData

struct PhotoClubsInnerView: View {

    @Environment(\.managedObjectContext) private var viewContext // may not be correct
    @FetchRequest var fetchRequest: FetchedResults<PhotoClub>
    private let permitDeletionOfPhotoClubs = true // disables .delete() functionality for this screen
    @Environment(\.layoutDirection) var layoutDirection // .leftToRight or .rightToLeft
    let accentColor: Color = .accentColor // needed to solve a typing issue
    @State private var coordinateRegions: [PhotoClubId: MKCoordinateRegion] = [:]
    private let defaultCoordRegion = MKCoordinateRegion( // used as a default if region is not found
                center: CLLocationCoordinate2D(latitude: 48.858222, longitude: 2.2945), // Eifel Tower, Paris
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

    // regenerate Section using dynamic FetchRequest with dynamic predicate and dynamic sortDescriptor
    init(predicate: NSPredicate) {
        _fetchRequest = FetchRequest<PhotoClub>(sortDescriptors: // replaces previous fetchRequest
                                                    [SortDescriptor(\.priority_, order: .reverse), // highest prio first
                                                     SortDescriptor(\.name_, order: .forward), // photoclubID=name&town
                                                     SortDescriptor(\.town_, order: .forward)],
                                                predicate: predicate,
                                                animation: .default)
    }

    var body: some View {
        ForEach(fetchRequest, id: \.id) { filteredPhotoClub in
            VStack {
                HStack(alignment: .center) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.white, .yellow, accentColor ) // yellow secondary color should not show up
                        .symbolRenderingMode(.palette)
                        .foregroundColor(.accentColor)
                        .font(.title)
                        .padding([.trailing], 5)
                    VStack(alignment: .leading) {
                        Text(verbatim: "\(filteredPhotoClub.fullName)")
                            .font(.title3)
                            .tracking(1)
                            .foregroundColor(.photoClubColor)
                        Text(verbatim: layoutDirection == .leftToRight ?
                             "\(filteredPhotoClub.town), \(filteredPhotoClub.country)" : // English, Dutch
                             "\(filteredPhotoClub.country) ,\(filteredPhotoClub.town)") // Hebrew, Arabic
                            .font(.subheadline)
                        Text("\(filteredPhotoClub.members.count) members (inc. ex-members)",
                             comment: "<count> members (including all types of members) within photo club")
                            .font(.subheadline)
                        if let url: URL = filteredPhotoClub.photoClubWebsite {
                            Link(destination: url, label: {
                                Text(url.absoluteString)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .font(.subheadline)
                                    .foregroundColor(.linkColor)
                            })
                                .buttonStyle(.plain) // to avoid entire List element to be clickable
                        }
                    }
                    Spacer()
                    Button(
                        action: {
                            openCloseSound(openClose: filteredPhotoClub.isScrollLocked ? .close : .open)
                            filteredPhotoClub.isScrollLocked.toggle()
                        },
                        label: {
                            HStack { // to make background color clickable too
                                LockAnimationView(locked: filteredPhotoClub.isScrollLocked)
                            }
                            .frame(maxWidth: 60, maxHeight: 60)
                            .contentShape(Rectangle())
                        }
                    )
                         .buttonStyle(.plain) // to avoid entire List element to be clickable
                }
                Map(coordinateRegion: binding(for: filteredPhotoClub.id),
                    interactionModes: filteredPhotoClub.isScrollLocked ? [] : [.pan, .zoom],
                    annotationItems: fetchRequest) { photoClub in
                    MapMarker( coordinate: photoClub.coordinates,
                               tint: photoClub == filteredPhotoClub ? .photoClubColor : .blue )
                }
                    .frame(minHeight: 300, idealHeight: 500, maxHeight: .infinity)
            }
            .onAppear(perform: {
                for filteredPhotoClub in fetchRequest {
                    coordinateRegions[filteredPhotoClub.id] = MKCoordinateRegion(
                        center: CLLocationCoordinate2D( latitude: filteredPhotoClub.latitude_,
                                                        longitude: filteredPhotoClub.longitude_),
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                    print(filteredPhotoClub.fullName + " in " + filteredPhotoClub.town)
                    print(coordinateRegions[filteredPhotoClub.id] as Any)
                }
            })
        }
        .onDelete(perform: deletePhotoClubs)
        .onDisappear(perform: { try? viewContext.save() }) // store map scroll lock states in database
//        .onAppear(perform: {
//            for filteredPhotoClub in fetchRequest {
//                coordinateRegions[filteredPhotoClub.id] = MKCoordinateRegion(
//                    center: CLLocationCoordinate2D( latitude: filteredPhotoClub.latitude_,
//                                                    longitude: filteredPhotoClub.longitude_),
//                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
//                print(filteredPhotoClub.fullName + " in " + filteredPhotoClub.town)
//                print(coordinateRegions[filteredPhotoClub.id] as Any)
//            }
//        })
        .accentColor(.photoClubColor)
    }

    private func binding(for key: PhotoClubId) -> Binding<MKCoordinateRegion> {
        // https://stackoverflow.com/questions/68430007/how-to-use-state-with-dictionary
        // https://forums.swift.org/t/swiftui-how-to-use-dictionary-as-binding/34967

        return .init(
            get: {
                print("key: \(key.fullName) in \(key.town)")
                print("map center: \(String(describing: coordinateRegions[key]?.center))")
                print("map span: \(String(describing: coordinateRegions[key]?.span))")
                return coordinateRegions[key] ?? defaultCoordRegion
            },
            set: { coordinateRegions[key] = $0 }
        )

    }

    func deletePhotoClubs(offsets: IndexSet) {
        guard permitDeletionOfPhotoClubs else { return } // to turn off the feature
        if let photoClub = (offsets.map { fetchRequest[$0] }.first) { // unwrap first PhotoClub to be deleted
            photoClub.deleteAllMembers(context: viewContext)
            guard photoClub.members.count == 0 else { // safety: will crash if member.photoClub == nil
                print("Could not delete photo club \(photoClub.fullName) " +
                      "because it still has \(photoClub.members.count) members.")
                return
            }
            offsets.map { fetchRequest[$0] }.forEach( viewContext.delete )

            do {
                if viewContext.hasChanges {
                    try viewContext.save()
                }
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }

    }

}

struct PhotoClubsInner_Previews: PreviewProvider {
    static let predicate = NSPredicate(format: "name_ = %@ || name_ = %@ || name_ = %@",
                                       argumentArray: ["PhotoClub2", "PhotoClub1", "PhotoClub3"])

    static var previews: some View {
        NavigationStack {
            List { // lists are "Lazy" automatically
                PhotoClubsInnerView(predicate: predicate)
                    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            }
            .navigationBarTitle(Text(String("PhotoClubInnerView"))) // prevent localization
        }
    }
}
