import Swiftdansi
import XCTest

final class SwiftdansiDemoTests: XCTestCase {
    func testStripKeepsContent() {
        let markdown = "# Title\n\n**Bold** and [Link](https://example.com)"
        let output = strip(markdown)
        XCTAssertTrue(output.contains("Title"))
        XCTAssertTrue(output.contains("Bold"))
        XCTAssertTrue(output.contains("Link"))
    }

    func testRenderProducesOutput() {
        let markdown = "Hello _world_"
        let output = render(markdown)
        XCTAssertFalse(output.isEmpty)
    }
}
