import Foundation
public extension HATypedRequest {
    /// Returns the exact configuration for a script in homeassistant
    ///
    /// - Parameters:
    ///   - entityId: The entity id of the script
    /// - Returns: A typed request that can be sent via `HAConnection`
    static func getScriptConfig(_ entityId: String) -> HATypedRequest<HAScriptConfig> {
        .init(request: .init(type: .scriptConfig, data: ["entity_id":entityId]))
    }
}

public struct HAScriptConfig: HADataDecodable {
    /// The script config to be returned
    public var config: HAScriptSubConfig
    
    /// Create with data
    /// - Parameter data: The data from the server
    /// - Throws: If any required keys are missing
    public init(data: HAData) throws {
        self.init(
            config: try data.decode("config")
        )
    }
    
    public init(config: HAScriptSubConfig) {
        self.config = config
    }
}

public struct HAScriptSubConfig: HADataDecodable {
    /// Friendly name for the script
    public var alias: String?
    /// Icon for the script
    public var icon: String?
    /// A description of the script that will be displayed in the Services tab under Developer Tools
    public var description: String?
    /// Variables that will be available inside your templates
    public var variables: [String: Any]?
    /// Controls what happens when script is invoked while it is still running from one or more previous invocations
    public var mode: Mode?
    /// Controls maximum number of runs executing and/or queued up to run at a time. Only valid with modes `queued` and `parallel`
    public var max: Int?
    /// When `max` is exceeded (which is effectively 1 for `single` mode) a log message will be emitted to indicate this has happened
    public var maxExceeded: String?
    /// The sequence of actions to be performed in the script
    public var sequence: NSArray
    
    /// Controls what happens when script is invoked while it is still running from one or more previous invocations
    public enum Mode: String, HADecodeTransformable {
        /// Do not start a new run. Issue a warning
        case single = "single"
        /// Start a new run after first stopping previous run
        case restart = "restart"
        /// Start a new run after all previous runs complete. Runs are guaranteed to execute in the order they were queued
        case queued = "queued"
        /// Start a new, independent run in parallel with previous runs
        case parallel = "parallel"
    }
    
    /// Create with data
    /// - Parameter data: The data from the server
    /// - Throws: If any required keys are missing
    public init(data: HAData) throws {
        self.init(
            alias: data.decode("alias", fallback: nil),
            icon: data.decode("icon", fallback: nil),
            description: data.decode("description", fallback: nil),
            variables: data.decode("variables", fallback: nil),
            mode: data.decode("mode", fallback: nil),
            max: data.decode("max", fallback: nil),
            maxExceeded: data.decode("maxExceeded", fallback: nil),
            sequence: try data.decode("sequence")
        )
    }

    /// Create with a given type and id
    /// - Parameters:
    ///   - alias: Friendly name for the script
    ///   - icon: Icon for the script
    ///   - description: A description of the script that will be displayed in the Services tab under Developer Tools
    ///   - variables: Variables that will be available inside your templates
    ///   - mode: Controls what happens when script is invoked while it is still running from one or more previous invocations
    ///   - max: Controls maximum number of runs executing and/or queued up to run at a time. Only valid with modes `queued` and `parallel`
    ///   - maxExceeded: When `max` is exceeded (which is effectively 1 for `single` mode) a log message will be emitted to indicate this has happened
    ///   - sequence: The sequence of actions to be performed in the script
    public init(alias: String?, icon: String?, description: String?, variables: [String: Any]?, mode: Mode?, max: Int?, maxExceeded: String?, sequence: NSArray) {
        self.alias = alias
        self.icon = icon
        self.description = description
        self.variables = variables
        self.mode = mode
        self.max = max
        self.maxExceeded = maxExceeded
        self.sequence = sequence
    }
}
