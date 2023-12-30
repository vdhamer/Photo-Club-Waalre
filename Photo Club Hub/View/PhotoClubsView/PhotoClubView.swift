//
//  PhotoClubView.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 30/12/2021.
//

import SwiftUI
import MapKit
import CoreData

struct PhotoClubView: View {

    @Environment(\.managedObjectContext) private var viewContext // may not be correct
    @Environment(\.layoutDirection) var layoutDirection // .leftToRight or .rightToLeft

    @FetchRequest var fetchedPhotoClubs: FetchedResults<PhotoClub>
    private let permitDeletionOfPhotoClubs = true // disables .delete() functionality for this screen
    let accentColor: Color = .accentColor // needed to solve a typing issue

    @State private var cameraPositions: [PhotoClubId: MapCameraPosition] = [:] // location of camera per club
    let interactionModes: MapInteractionModes = [.pan, .zoom, .rotate, .pitch]
    @State private var mapSelection: MKMapItem? // selected Anotation, if any

    // regenerate Section using dynamic FetchRequest with dynamic predicate and dynamic sortDescriptor
    init(predicate: NSPredicate) {
        _fetchedPhotoClubs = FetchRequest<PhotoClub>(sortDescriptors: // replaces previous fetchRequest
                                                    [SortDescriptor(\.pinned, order: .reverse), // pinned clubs first
                                                     SortDescriptor(\.name_, order: .forward), // photoclubID=name&town
                                                     SortDescriptor(\.town_, order: .forward)],
                                                     predicate: predicate,
                                                     animation: .bouncy)
    }

    var body: some View {
        ForEach(fetchedPhotoClubs, id: \.id) { filteredPhotoClub in
            Section {
                VStack(alignment: .leading) {
                    Text(verbatim: "\(filteredPhotoClub.fullName)")
                        .font(UIDevice.isIPad ? .title : .title2)
                        .tracking(1)
                        .foregroundColor(.photoClubColor)

                    HStack(alignment: .center, spacing: 0) {
//                        Image(systemName: "camera.circle.fill") TODO remove comment
                        Image(systemName: systemName(organizationType: filteredPhotoClub.organizationType,
                                                     circleNeeded: true)
                        )
                            .foregroundStyle(.white, .yellow, accentColor ) // secondary = yellow color not really used
                            .symbolRenderingMode(.palette)
                            .font(.largeTitle)
                            .padding(.horizontal, 5)
                        VStack(alignment: .leading) {
                            Text(verbatim: layoutDirection == .leftToRight ?
                                 "\(filteredPhotoClub.localizedTown), \(filteredPhotoClub.localizedCountry)" : // EN, NL
                                 "\(filteredPhotoClub.localizedCountry) ,\(filteredPhotoClub.localizedTown)") // HE, AR
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
                        Spacer() // moved Button to trailing/right side
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
                    .padding(.all, 0)
                    Map(position: cameraPositionBinding(for: filteredPhotoClub.id),
                        interactionModes: filteredPhotoClub.isScrollLocked ? [] : [
                            .rotate, // automatically enables the compas button when rotated
                            .pitch, // switch to 3D view if zoomed in far enough
                            .pan, .zoom], // actually .all is the default
//                        userTrackingMode: .constant(.follow),
                        selection: $mapSelection) {

                        // show markers
                        ForEach(toMapItems(photoClubs: fetchedPhotoClubs), id: \.self) { mapItem in
                            Marker(isEqual(mapItemLHS: mapItem, mapItemRHS: mapSelection) ?
                                mapItem.name ?? "NoName??" : String(""),
                                   systemImage: systemName(organizationType: filteredPhotoClub.organizationType,
                                                           circleNeeded: false),
                                   coordinate: mapItem.placemark.coordinate)
                                .tint(isEqual(mapItem: mapItem, photoclub: filteredPhotoClub) ? .photoClubColor : .blue)
                        }

                        UserAnnotation() // show user's location on map
                    }
                        .frame(minHeight: 300, idealHeight: 500, maxHeight: .infinity)
                } // VStack
                .task {
                    initializeCameraPosition(photoClub: filteredPhotoClub) // works better than .onAppear(perform:)?
                }
                .onAppear {
                    // on main queue (avoid accessing NSManagedObjects on background thread!)
                    let clubName = filteredPhotoClub.fullName
                    let town = filteredPhotoClub.town // untranslated
                    let coordinates = filteredPhotoClub.coordinates

                    Task.detached { // other (non-bgContext) background thread to access 2 async functions
                        var localizedTown: String?
                        var localizedCountry: String?
                        do {
                            let (locality, nation) =
                                try await reverseGeocode(coordinates: coordinates)
                            localizedTown = locality
                            localizedCountry = nation
                            await updateTownCountry(clubName: clubName, town: town,
                                                    localizedTown: localizedTown, localizedCountry: localizedCountry)
                        } catch {
                            print("""
                                  ERROR: could not reverseGeocode (\
                                  \(filteredPhotoClub.coordinates.latitude), \
                                  \(filteredPhotoClub.coordinates.longitude))
                                  """)
                        }
                    }
                }
                .onDisappear(perform: { try? viewContext.save() }) // persist map scroll-lock states when leaving page
                .accentColor(.photoClubColor)
                .listRowSeparator(.hidden)
                .padding()
                .border(Color(.darkGray), width: 0.5)
                .background(Color(.secondarySystemBackground)) // compatible with light and dark mode
                .mapControls {
                    MapCompass() // map Compass shown if rotation differs from North on top
                    MapPitchToggle() // switch between 2D and 3D
                    MapScaleView() // distance scale
                    MapUserLocationButton()
                } .mapControlVisibility(filteredPhotoClub.isScrollLocked ? .hidden : .automatic)
            } // Section
        } // outer ForEach (PhotoClub)
        .onDelete(perform: deleteOrganizations)
    }

    // find PhotoClub using identifier (clubName,oldTown) and fill (newTown,newCountry) in CoreData database
    private func updateTownCountry(clubName: String, town: String,
                                   localizedTown: String?, localizedCountry: String?) async {

        guard (localizedTown != nil) && (localizedCountry != nil) else { return } // nothing to update

        let bgContext = PersistenceController.shared.container.newBackgroundContext() // background thread
        bgContext.name = "reverseGeocode \(clubName)"
        bgContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        bgContext.performAndWait { // block must be synchronous and CoreData operations must occur on bgContext thread
            let fetchRequest: NSFetchRequest<PhotoClub>
            fetchRequest = PhotoClub.fetchRequest()

            // Create the component predicates
            let clubPredicate = NSPredicate(format: "name_ = %@", clubName)
            let townPredicate = NSPredicate(format: "town_ = %@", town)

            fetchRequest.predicate = NSCompoundPredicate(
                andPredicateWithSubpredicates: [clubPredicate, townPredicate]
            )

            let photoClub = try? bgContext.fetch(fetchRequest).first
            guard let photoClub else {
                print("ERROR: couldn't find photo club in CordeData query")
                return
            }

            print("""
                  Photo Club: \(photoClub.fullName), \(photoClub.town) -> \
                  \(String(describing: localizedTown)), \(String(describing: localizedCountry))
                  """)

            if let localizedTown { photoClub.localizedTown = localizedTown }
            if let localizedCountry { photoClub.localizedCountry = localizedCountry}
            do {
                try bgContext.save() // persist Town, Country or both for an organization
            } catch {
                print("""
                      ERROR: could not save \
                      \(localizedTown ?? "nil"), \(localizedCountry ?? "nil") \
                      for \(clubName) to CoreData
                      """)
            }
        }
    }

    // conversion to [MKMapItems] is needed to make Placemarks touch (and mouse) sensitive
    private func toMapItems(photoClubs: FetchedResults<PhotoClub>) -> [MKMapItem] {
        var mapItems: [MKMapItem] = []
        for photoClub in photoClubs {
            let coordinates = CLLocationCoordinate2D(latitude: photoClub.latitude_,
                                                     longitude: photoClub.longitude_)
            let placemark = MKPlacemark(coordinate: coordinates)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = photoClub.fullName
            mapItems.append(mapItem)
        }
        return mapItems
    }

    private func initializeCameraPosition(photoClub: PhotoClub) {
        let mapCameraPosition: MapCameraPosition

        mapCameraPosition = MapCameraPosition.region(MKCoordinateRegion(
            center: CLLocationCoordinate2D( latitude: photoClub.latitude_,
                                            longitude: photoClub.longitude_),
            latitudinalMeters: 10000, longitudinalMeters: 10000) // 10 km
        )
        cameraPositions[photoClub.id] = mapCameraPosition // return MapCameraPosition and don't use input param
    }

    private func cameraPositionBinding(for key: PhotoClubId) -> Binding<MapCameraPosition> {
        let defaultCameraPosition = MapCameraPosition.region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 6.52396), // island on the equator
                    latitudinalMeters: 100000, longitudinalMeters: 100000)
        )

        // https://stackoverflow.com/questions/68430007/how-to-use-state-with-dictionary
        // https://forums.swift.org/t/swiftui-how-to-use-dictionary-as-binding/34967
        return .init( // a bit ackward, but the geter does return a binding
            get: { return cameraPositions[key] ?? defaultCameraPosition },
            set: { newValue in cameraPositions[key] = newValue } // is this working correctly?
        )
    }

    private func deleteOrganizations(offsets: IndexSet) {
        guard permitDeletionOfPhotoClubs else { return } // to turn off the feature
        if let photoClub = (offsets.map { fetchedPhotoClubs[$0] }.first) { // unwrap first PhotoClub to be deleted
            photoClub.deleteAllMembers(context: viewContext)
            guard photoClub.members.count == 0 else { // safety: will crash if member.photoClub == nil
                print("Could not delete photo club \(photoClub.fullName) " +
                      "because it still has \(photoClub.members.count) members.")
                return
            }
            offsets.map { fetchedPhotoClubs[$0] }.forEach( viewContext.delete )

            do {
                if viewContext.hasChanges {
                    try viewContext.save() // persist deletion of organization
                }
            } catch {
                let nsError = error as NSError
                ifDebugFatalError("Unresolved error \(nsError), \(nsError.userInfo)",
                                  file: #fileID, line: #line) // likely deprecation of #fileID in Swift 6.0
                // in release mode, the failed deletion is only logged. App doesn't stop.
            }
        }

    }

}

extension PhotoClubView {

//    func tint(mapItem: MapItem, selectedClub: PhotoClub) -> Color { // TODO
//        if isEqual(mapItem: mapItem, photoclub: selectedClub) {
//            .photoClubColor
//        } else if mapItem {
//            mapItem
//        } else {
//            .blue
//        }
//    }

    func systemName(organizationType: OrganizationType?, circleNeeded: Bool) -> String { // for SanFrancisco symbols
        guard let organizationType else { return "questionmark.circle.fill" }

        var result: String

        switch organizationType.name {
        case OrganizationTypeEnum.museum.rawValue:
            result = "building.columns.fill"
        case OrganizationTypeEnum.club.rawValue:
            result = "camera.fill"
        default:
            result = "location.fill"
        }

        if circleNeeded {
            result = result.replacing(".fill", with: ".circle.fill")
        }
//    Image(systemName: filteredPhotoClub.organizationType.name == OrganizationTypeEnum.club.rawValue ?
//          "camera.circle.fill" : "building.columns.circle.fill" // use function for more options
        return result
    }

}

extension PhotoClubView { // reverse GeoCoding

    func reverseGeocode(coordinates: CLLocationCoordinate2D) async throws -> (city: String?, country: String?) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinates.latitude,
                                  longitude: coordinates.longitude)

        guard let placemark = try await geocoder.reverseGeocodeLocation(location).first else {
            throw CLError(.geocodeFoundNoResult)
        }

        let town = placemark.locality
        let country = placemark.country
        return (town, country)
    }

}

extension PhotoClubView {

    static var userLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 51.39184, longitude: 5.46144) // Waalre
    }

    static var userRegion: MKCoordinateRegion {
        MKCoordinateRegion(center: PhotoClubView.userLocation,
                           latitudinalMeters: 10000, longitudinalMeters: 10000)
    }
}

extension PhotoClubView { // tests for equality

    private func isEqual(mapItem: MKMapItem, photoclub: PhotoClub) -> Bool {
        // a little bit scary to compare two floats for equality, but for now it only affects the color of the marker
        if mapItem.placemark.coordinate.latitude != photoclub.coordinates.latitude {
            return false
        } else {
            return mapItem.placemark.coordinate.longitude == photoclub.coordinates.longitude
        }
    }

    private func isEqual(mapItemLHS: MKMapItem, mapItemRHS: MKMapItem?) -> Bool {
        // a little bit scary to compare two floats for equality
        if mapItemLHS.placemark.coordinate.latitude != mapItemRHS?.placemark.coordinate.latitude {
            return false
        } else {
            return mapItemLHS.placemark.coordinate.longitude == mapItemRHS?.placemark.coordinate.longitude
        }
    }

}

struct PhotoClubsView_Previews: PreviewProvider {
    static let predicate = NSPredicate(format: "name_ = %@ || name_ = %@ || name_ = %@",
                                       argumentArray: ["PhotoClub2", "PhotoClub1", "PhotoClub3"])

    static var previews: some View {
        NavigationStack {
            List { // lists are "Lazy" automatically
                PhotoClubView(predicate: predicate)
                    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            }
            .navigationBarTitle(Text(String("PhotoClubInnerView"))) // prevent localization
        }
    }
}
