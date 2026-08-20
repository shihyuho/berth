import BerthCore
import Foundation

struct LatestReleaseClient {
    enum Error: Swift.Error, Equatable {
        case invalidResponse
        case unsuccessfulStatus(Int)
        case unpublishedRelease
    }

    typealias DataLoader = (URLRequest) async throws -> (Data, URLResponse)

    private static let latestReleaseURL = URL(
        string: "https://api.github.com/repos/shihyuho/berth/releases/latest"
    )!
    private let dataLoader: DataLoader

    init(session: URLSession = .shared) {
        dataLoader = { request in
            try await session.data(for: request)
        }
    }

    init(dataLoader: @escaping DataLoader) {
        self.dataLoader = dataLoader
    }

    func fetchLatestRelease() async throws -> UpdateRelease {
        var request = URLRequest(url: Self.latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("Berth", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await dataLoader(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw Error.unsuccessfulStatus(httpResponse.statusCode)
        }
        let payload = try JSONDecoder().decode(LatestReleasePayload.self, from: data)
        guard !payload.isDraft, !payload.isPrerelease else {
            throw Error.unpublishedRelease
        }
        return UpdateRelease(version: payload.tagName, detailsURL: payload.htmlURL)
    }
}

private struct LatestReleasePayload: Decodable {
    let tagName: String
    let htmlURL: URL
    let isDraft: Bool
    let isPrerelease: Bool

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case isDraft = "draft"
        case isPrerelease = "prerelease"
    }
}
