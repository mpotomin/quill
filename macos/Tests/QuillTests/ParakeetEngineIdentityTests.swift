import XCTest

@testable import quill

/// The engine reports the name and model recorded in transcript metadata.
final class ParakeetEngineIdentityTests: XCTestCase {
    func testEngineIdentifiesAsParakeetV3() {
        let engine = ParakeetEngine()
        XCTAssertEqual(engine.name, "parakeet")
        XCTAssertEqual(engine.model, "parakeet-tdt-0.6b-v3-coreml")
    }
}
