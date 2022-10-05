public extension HATypedRequest {
    /// Retrieve a list of the user's areas
    ///
    /// - Returns: A typed request that can be sent via `HAConnection`
    static func getAreas() -> HATypedRequest<[HAArea]> {
        .init(request: .init(type: .getAreas, data: [:]))
    }
}

public struct HAArea: HADataDecodable {
    /// The id of the area, as in homeassistant
    public var id: String
    /// The friendly name of the area
    public var name: String
    /// The url to the picture of the area
    public var picture: String?

    /// Create with data
    /// - Parameter data: The data from the server
    /// - Throws: If any required keys are missing
    public init(data: HAData) throws {
        self.init(
            id: try data.decode("area_id"),
            name: try data.decode("name"),
            picture: data.decode("picture", fallback: nil)
        )
    }

    /// Create with a given type and id
    /// - Parameters:
    ///   - type: The id of the area
    ///   - id: The name of the area
    ///   - picture: URL path to the image of the area
    public init(id: String, name: String, picture: String?) {
        self.id = id
        self.name = name
        self.picture = picture
    }
}
