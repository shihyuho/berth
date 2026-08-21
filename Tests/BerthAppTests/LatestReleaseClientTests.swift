import BerthCore
import Foundation
import XCTest

@testable import Berth

final class LatestReleaseClientTests: XCTestCase {
    func testPublishedReleaseResponseMapsToUpdateRelease() async throws {
        let expectedURL = URL(string: "https://github.com/shihyuho/berth/releases/tag/1.3.0")!
        let client = LatestReleaseClient { request in
            XCTAssertEqual(
                request.url,
                URL(string: "https://api.github.com/repos/shihyuho/berth/releases/latest")
            )
            XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
            let data = Data(
                """
                {
                  "tag_name": "1.3.0",
                  "html_url": "\(expectedURL.absoluteString)",
                  "draft": false,
                  "prerelease": false
                }
                """.utf8
            )
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }

        let release = try await client.fetchLatestRelease()

        XCTAssertEqual(release, UpdateRelease(version: "1.3.0", detailsURL: expectedURL))
    }

    func testRateLimitedResponseFailsWithoutOfferingItsBody() async throws {
        let client = LatestReleaseClient { request in
            let data = Data(
                """
                {
                  "tag_name": "99.0.0",
                  "html_url": "https://example.com/untrusted",
                  "draft": false,
                  "prerelease": false
                }
                """.utf8
            )
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 403,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }

        do {
            _ = try await client.fetchLatestRelease()
            XCTFail("A rate-limited response must fail")
        } catch {
            XCTAssertNotNil(error as? LatestReleaseClient.Error)
        }
    }

    func testDraftReleaseResponseIsRejected() async throws {
        let client = LatestReleaseClient { request in
            let data = Data(
                """
                {
                  "tag_name": "1.3.0",
                  "html_url": "https://github.com/shihyuho/berth/releases/tag/1.3.0",
                  "draft": true,
                  "prerelease": false
                }
                """.utf8
            )
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }

        do {
            _ = try await client.fetchLatestRelease()
            XCTFail("A draft release must not be offered")
        } catch {
            XCTAssertEqual(error as? LatestReleaseClient.Error, .unpublishedRelease)
        }
    }

    func testPrereleaseResponseIsRejected() async throws {
        let client = LatestReleaseClient { request in
            let data = Data(
                """
                {
                  "tag_name": "1.3.0-beta.1",
                  "html_url": "https://github.com/shihyuho/berth/releases/tag/1.3.0-beta.1",
                  "draft": false,
                  "prerelease": true
                }
                """.utf8
            )
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }

        do {
            _ = try await client.fetchLatestRelease()
            XCTFail("A prerelease must not be offered")
        } catch {
            XCTAssertEqual(error as? LatestReleaseClient.Error, .unpublishedRelease)
        }
    }
}
