import XCTest
@testable import quill

final class ParakeetEngineIdentityTests: XCTestCase {
    func testEngineIdentifiesAsParakeetV3() {
        let engine = ParakeetEngine()
        XCTAssertEqual(engine.name, "parakeet")
        XCTAssertEqual(engine.model, "parakeet-tdt-0.6b-v3-coreml")
    }
}
