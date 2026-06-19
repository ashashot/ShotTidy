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

    private var queryString: String {
        [placeName, address, city, country]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
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
        let query = queryString
        guard !query.isEmpty else {
            geocodeState = .failed
            return
        }

        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(query)
            if let location = placemarks.first?.location {
                let coord = location.coordinate
                coordinate = coord
                cameraPosition = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                ))
                geocodeState = .ready
            } else {
                geocodeState = .failed
            }
        } catch {
            geocodeState = .failed
        }
    }

    // MARK: - Open Apple Maps

    private func openInMaps(coordinate: CLLocationCoordinate2D) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
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
