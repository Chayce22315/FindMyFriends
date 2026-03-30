import Foundation

struct BackendFamilyResponse: Codable {
    let id: UUID
    let name: String
    let inviteCode: String
    let inviteUrl: String
    let createdAt: Date
}

struct BackendErrorResponse: Codable {
    let error: String?
}

enum BackendClientError: Error, LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Backend URL is invalid."
        case .invalidResponse:
            return "Unexpected response from the backend."
        case .server(let message):
            return message
        }
    }
}

final class BackendClient {
    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(baseURLString: String, session: URLSession = .shared) throws {
        guard let url = BackendClient.normalizeBaseURL(baseURLString) else {
            throw BackendClientError.invalidBaseURL
        }
        self.baseURL = url
        self.session = session
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func createFamily(name: String) async throws -> BackendFamilyResponse {
        let payload = CreateFamilyPayload(name: name)
        let request = try buildRequest(path: "/api/families", body: payload)
        return try await send(request)
    }

    func joinFamily(code: String) async throws -> BackendFamilyResponse {
        let payload = JoinFamilyPayload(code: code)
        let request = try buildRequest(path: "/api/families/join", body: payload)
        return try await send(request)
    }

    private func buildRequest<T: Encodable>(path: String, body: T) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw BackendClientError.invalidBaseURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BackendClientError.invalidResponse
        }

        if (200 ..< 300).contains(http.statusCode) {
            return try decoder.decode(T.self, from: data)
        }

        if let error = try? decoder.decode(BackendErrorResponse.self, from: data),
           let message = error.error, !message.isEmpty {
            throw BackendClientError.server(message)
        }

        throw BackendClientError.invalidResponse
    }

    private static func normalizeBaseURL(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let hasScheme = trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://")
        let withScheme = hasScheme ? trimmed : "http://\(trimmed)"
        let normalized = withScheme.hasSuffix("/") ? String(withScheme.dropLast()) : withScheme
        return URL(string: normalized)
    }
}

private struct CreateFamilyPayload: Codable {
    let name: String
}

private struct JoinFamilyPayload: Codable {
    let code: String
}
