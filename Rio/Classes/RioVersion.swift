/// Single source of truth for the SDK version.
///
/// Reported to the backend as the `rio-sdk-version` request header, and read by
/// `Rio.podspec` so `s.version` cannot drift from what the header sends. Bump it
/// here and nowhere else, and tag the release with the same number so Swift
/// Package Manager consumers resolve a matching version.
enum RioSDKVersion {
    static let current = "0.1.0-beta.1"
}
