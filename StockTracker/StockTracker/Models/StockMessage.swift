import Foundation

struct MessagesResponse: Codable, Equatable {
    let messages: [StockMessage]
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case messages
        case hasMore = "has_more"
    }
}

struct StockMessage: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let rawJSON: [String: JSONValue]

    init(id: String, rawJSON: [String: JSONValue]) {
        self.id = id
        self.rawJSON = rawJSON
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var dict: [String: JSONValue] = [:]

        for key in container.allKeys {
            dict[key.stringValue] = try container.decode(JSONValue.self, forKey: key)
        }

        guard let id = dict["id"]?.stringValue else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Message missing 'id' field")
            )
        }

        self.id = id
        self.rawJSON = dict
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        for (key, value) in rawJSON {
            guard let codingKey = DynamicCodingKey(stringValue: key) else { continue }
            try container.encode(value, forKey: codingKey)
        }
    }

    var displayFields: [(key: String, value: String)] {
        rawJSON
            .sorted { $0.key < $1.key }
            .map { (key: $0.key, value: $0.value.displayString) }
    }
}

enum JSONValue: Codable, Equatable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var displayString: String {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        case .double(let value): return String(format: "%.2f", value)
        case .bool(let value): return value ? "true" : "false"
        case .null: return "—"
        case .array(let values):
            return values.map(\.displayString).joined(separator: ", ")
        case .object(let dict):
            guard let data = try? JSONEncoder.pretty.encode(dict),
                  let string = String(data: data, encoding: .utf8) else {
                return "{}"
            }
            return string
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }
}

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}

private extension JSONEncoder {
    static let pretty: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}
