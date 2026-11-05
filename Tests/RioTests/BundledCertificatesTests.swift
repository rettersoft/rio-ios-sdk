import XCTest
import Security
@testable import Rio

/// The SSL pinning certificates in `Rio/Assets` must ship with the SDK on every package manager.
/// Before 0.1.0 Swift Package Manager silently dropped them and pinning fell back to "off".
final class BundledCertificatesTests: XCTestCase {
    func testAllFivePinningCertificatesAreBundledAndParse() throws {
        for index in 1...5 {
            let url = try XCTUnwrap(Rio.bundledCertificateURL(named: "\(index)"), "\(index).cer is not in the SDK bundle")
            let data = try Data(contentsOf: url)
            XCTAssertNotNil(SecCertificateCreateWithData(nil, data as CFData), "\(index).cer is not a DER certificate")
        }
    }
}
