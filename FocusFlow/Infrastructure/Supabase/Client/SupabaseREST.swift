import Foundation

enum SupabaseRESTError: Error, LocalizedError {
    case missingConfig(String)
    case badResponse(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .missingConfig(let key):
            return "Missing config: \(key)"
        case .badResponse(let status, let body):
            return "badResponse(status: \(status), body: \(body))"
        }
    }
}

enum SupabaseEnv {

    static var url: URL {
        // 1) Prefer Info.plist (if present)
        if let s = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           let u = URL(string: s) {
            return u
        }

        // 2) Fallback to SupabaseConfig.shared (your hardcoded config)
        return SupabaseConfig.shared.projectURL
    }

    static var anonKey: String {
        // 1) Prefer Info.plist (if present)
        if let s = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           !s.isEmpty {
            return s
        }

        // 2) Fallback to SupabaseConfig.shared
        let k = SupabaseConfig.shared.anonKey
        if k.isEmpty {
            fatalError("Missing SUPABASE_ANON_KEY (Info.plist missing and SupabaseConfig.shared.anonKey is empty)")
        }
        return k
    }
}

enum SupabaseJSON {
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            if let date = f.date(from: s) { return date }

            let f2 = ISO8601DateFormatter()
            f2.formatOptions = [.withInternetDateTime]
            if let date = f2.date(from: s) { return date }

            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Invalid ISO8601 date: \(s)")
        }
        return d
    }()

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        e.dateEncodingStrategy = .custom { date, encoder in
            var c = encoder.singleValueContainer()
            try c.encode(f.string(from: date))
        }
        return e
    }()
}

struct SupabaseREST {
    static func request(
        path: String,
        method: String,
        query: [URLQueryItem] = [],
        bearerToken: String,
        body: Data? = nil,
        extraHeaders: [String: String] = [:]
    ) async throws -> Data {
        var url = SupabaseEnv.url
        url.appendPathComponent(path)

        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            comps.queryItems = query
        }

        var req = URLRequest(url: comps.url!)
        req.httpMethod = method
        req.httpBody = body

        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseEnv.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        for (k, v) in extraHeaders {
            req.setValue(v, forHTTPHeaderField: k)
        }

        let (data, resp) = try await URLSession.shared.data(for: req)
        let http = resp as? HTTPURLResponse
        let status = http?.statusCode ?? -1

        if (200..<300).contains(status) {
            return data
        } else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseRESTError.badResponse(status: status, body: bodyStr)
        }
    }
}
