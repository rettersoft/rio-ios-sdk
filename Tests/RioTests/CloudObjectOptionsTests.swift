import XCTest
@testable import Rio

final class CloudObjectOptionsTests: XCTestCase {
    /// Call sites written against 0.0.x leave `useLocal` out; they must keep compiling.
    func testUseLocalIsOptionalAndDefaultsToNil() {
        let options = RioCloudObjectOptions(classID: "Test", method: "sayHello")
        XCTAssertNil(options.useLocal)
        XCTAssertNil(RioCloudObjectOptions().useLocal)
    }

    func testExplicitUseLocalIsKept() {
        XCTAssertEqual(RioCloudObjectOptions(classID: "Test", instanceID: "1", useLocal: true).useLocal, true)
        XCTAssertEqual(RioCloudObjectOptions(classID: "Test", useLocal: false).useLocal, false)
    }
}
