//
//  PlaceMapView.swift
//  ShotTidy
//
//  Map card shown in ItemDetailView for the "places" category.
//  Geocodes the stored address fields and pins the location on a map.
//  Includes a button to open Apple Maps with turn-by-turn directions.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - PlaceMapView

struct PlaceMapView: View {

    let placeName: String
    let address: String?
    let city: String?
    let country: String?

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var coordinate: CLLocationCoordinate2D? = nil
    @State private var geocodeState: GeocodeState = .loading

    /// Queries tried in order until one resolves. The full string works best, but
    /// a place name the geocoder does not know can sink an otherwise valid address,
    /// so the address alone and the name with its city are tried next.
    private var queryStrings: [String] {
        func joined(_ parts: [String?]) -> String {
            parts
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
        }
        var queries: [String] = []
        let hasAddress = !(address?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        for query in [
            joined([placeName, address, city, country]),
            hasAddress ? joined([address, city, country]) : "",
            joined([placeName, city, country]),
        ] where !query.isEmpty && !queries.contains(query) {
            queries.append(query)
        }
        return queries
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch geocodeState {
            case .loading:
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(height: 180)
                    ProgressView()
                }

            case .failed:
                EmptyView()

            case .ready:
                mapCard
            }
        }
        .task { await geocode() }
    }

    // MARK: - Map card

    @ViewBuilder
    private var mapCard: some View {
        if let coord = coordinate {
            VStack(spacing: 0) {
                Map(position: .constant(cameraPosition)) {
                    Marker(placeName, coordinate: coord)
                        .tint(.red)
                }
                .frame(height: 180)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 16, bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0, topTrailingRadius: 16
                ))
                .allowsHitTesting(false)

                Button(action: { openInMaps(coordinate: coord) }) {
                    HStack {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Get Directions")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(Color(red: 0.88, green: 0.18, blue: 0.18))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(Color(.secondarySystemGroupedBackground))
                }
                .buttonStyle(.plain)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: 16,
                    bottomTrailingRadius: 16, topTrailingRadius: 0
                ))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Geocoding

    private func geocode() async {
        for query in queryStrings {
            guard let coord = await coordinate(for: query) else { continue }
            coordinate = coord
            cameraPosition = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            ))
            geocodeState = .ready
            return
        }
        geocodeState = .failed
    }

    /// First coordinate the geocoder returns for `query`, or nil when nothing matches.
    private func coordinate(for query: String) async -> CLLocationCoordinate2D? {
        do {
            if #available(iOS 26, *) {
                guard let request = MKGeocodingRequest(addressString: query) else { return nil }
                return try await request.mapItems.first?.location.coordinate
            } else {
                return try await CLGeocoder().geocodeAddressString(query).first?.location?.coordinate
            }
        } catch {
            return nil
        }
    }

    // MARK: - Open Apple Maps

    private func openInMaps(coordinate: CLLocationCoordinate2D) {
        let mapItem: MKMapItem
        if #available(iOS 26, *) {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            mapItem = MKMapItem(location: location, address: nil)
        } else {
            mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        }
        mapItem.name = placeName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - GeocodeState

private enum GeocodeState {
    case loading, ready, failed
}
