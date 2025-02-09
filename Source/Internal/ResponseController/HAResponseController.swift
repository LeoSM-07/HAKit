import Foundation
import Starscream

internal protocol HAResponseControllerDelegate: AnyObject {
    func responseController(
        _ controller: HAResponseController,
        didTransitionTo phase: HAResponseControllerPhase
    )
    func responseController(
        _ controller: HAResponseController,
        didReceive response: HAWebSocketResponse
    )
}

internal enum HAResponseControllerPhase: Equatable {
    case auth
    case command(version: String)
    case disconnected(error: Error?, forReset: Bool)

    static func == (lhs: HAResponseControllerPhase, rhs: HAResponseControllerPhase) -> Bool {
        switch (lhs, rhs) {
        case (.auth, .auth):
            return true
        case let (.command(lhsVersion), .command(rhsVersion)):
            return lhsVersion == rhsVersion
        case let (.disconnected(lhsError, lhsReset), .disconnected(rhsError, rhsReset)):
            return lhsError as NSError? == rhsError as NSError? && lhsReset == rhsReset
        default: return false
        }
    }
}

internal protocol HAResponseController: AnyObject {
    var delegate: HAResponseControllerDelegate? { get set }
    var workQueue: DispatchQueue { get set }
    var phase: HAResponseControllerPhase { get }

    func reset()
    func didReceive(event: Starscream.WebSocketEvent)
}

internal class HAResponseControllerImpl: HAResponseController {
    weak var delegate: HAResponseControllerDelegate?
    var workQueue: DispatchQueue = .global()

    private(set) var phase: HAResponseControllerPhase = .disconnected(error: nil, forReset: true) {
        didSet {
            if oldValue != phase {
                HAGlobal.log(.info, "phase transition to \(phase)")
            }
            delegate?.responseController(self, didTransitionTo: phase)
        }
    }

    func reset() {
        phase = .disconnected(error: nil, forReset: true)
    }

    func didReceive(event: Starscream.WebSocketEvent) {
        switch event {
        case let .connected(headers):
            HAGlobal.log(.info, "connected with headers: \(headers)")
            phase = .auth
        case let .disconnected(reason, code):
            HAGlobal.log(.info, "disconnected: \(reason) with code: \(code)")
            phase = .disconnected(error: nil, forReset: false)
        case let .text(string):
            workQueue.async { [self] in
                let response: HAWebSocketResponse

                do {
                    // https://forums.swift.org/t/can-encoding-string-to-data-with-utf8-fail/22437/4
                    let data = string.data(using: .utf8)!

                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        throw HAError.internal(debugDescription: "couldn't convert to dictionary")
                    }

                    response = try HAWebSocketResponse(dictionary: json)
                } catch {
                    HAGlobal.log(.error, "text parse error: \(error)")
                    return
                }

                switch response {
                case let .auth(state):
                    HAGlobal.log(.info, "Received: auth: \(state)")
                case let .event(identifier: identifier, data: _):
                    HAGlobal.log(.info, "Received: event: for \(identifier)")
                case let .result(identifier: identifier, result: result):
                    switch result {
                    case .success:
                        HAGlobal.log(.info, "Received: result success \(identifier)")
                    case let .failure(error):
                        HAGlobal.log(.info, "Received: result failure \(identifier): \(error) via \(string)")
                    }
                }

                DispatchQueue.main.async {
                    if case let .auth(.ok(version)) = response {
                        self.phase = .command(version: version)
                    }

                    self.delegate?.responseController(self, didReceive: response)
                }
            }
        case let .binary(data):
            HAGlobal.log(.info, "Received binary data: \(data.count)")
        case .ping:
            HAGlobal.log(.info, "Ping")
        case .pong:
            HAGlobal.log(.info, "Pong")
        case let .reconnectSuggested(isSuggested):
            HAGlobal.log(.info, "Reconnect suggested: \(isSuggested)")
        case let .viabilityChanged(isViable):
            HAGlobal.log(.info, "Viability changed: \(isViable)")
        case .cancelled:
            HAGlobal.log(.info, "Cancelled")
            phase = .disconnected(error: nil, forReset: false)
        case let .error(error):
            HAGlobal.log(.error, "Error: \(String(describing: error))")
            phase = .disconnected(error: error, forReset: false)
        }
    }
}
