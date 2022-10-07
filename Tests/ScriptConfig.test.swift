@testable import HAKit
import XCTest

internal class ScriptConfigTests: XCTestCase {
    func testRequest() {
        let request = HATypedRequest<HAScriptConfig>.getScriptConfig("script.test")
        XCTAssertEqual(request.request.type, .scriptConfig)
        XCTAssertEqual(request.request.data.count, 1)
        XCTAssertEqual(request.request.shouldRetry, true)
    }

    func testResponseWithFullValues() throws {
        let data = HAData(testJsonString: """
        {
          "config": {
            "alias": "Wake Up",
            "icon": "mdi:party-popper",
            "description": "Turns on the bedroom lights and then the living room lights after a delay",
            "variables": {
              "turn_on_entity": "group.living_room"
            },
            "fields": {
              "minutes": {
                "name": "Minutes",
                "description": "The amount of time to wait before turning on the living room lights",
                "selector": {
                  "number": {
                    "min": 0,
                    "max": 60,
                    "step": 1,
                    "unit_of_measurement": "minutes",
                    "mode": "slider"
                  }
                }
              }
            },
            "mode": "restart",
            "sequence": [
              {
                "event": "LOGBOOK_ENTRY",
                "event_data": {
                  "name": "Paulus",
                  "message": "is waking up",
                  "entity_id": "device_tracker.paulus",
                  "domain": "light"
                }
              },
              {
                "alias": "Bedroom lights on",
                "service": "light.turn_on",
                "target": {
                  "entity_id": "group.bedroom"
                },
                "data": {
                  "brightness": 100
                }
              },
              {
                "delay": {
                  "minutes": "{{ minutes }}"
                }
              },
              {
                "alias": "Living room lights on",
                "service": "light.turn_on",
                "target": {
                  "entity_id": "{{ turn_on_entity }}"
                }
              }
            ]
          }
        }
        """)
        let config = try HAScriptConfig(data: data)
        let result = config.config
        XCTAssertEqual(result.alias, "Wake Up")
        XCTAssertEqual(result.icon, "mdi:party-popper")
        XCTAssertEqual(result.description, "Turns on the bedroom lights and then the living room lights after a delay")
        XCTAssertEqual(result.variables?.count, 1)
        XCTAssertEqual(result.mode, .restart)
        XCTAssertEqual(result.sequence.count, 4)
        
        let sequence1 = try result.sequence.get(throwing: 0)
        let sequence2 = try result.sequence.get(throwing: 1)
        XCTAssertEqual(sequence1.count, 2)
        XCTAssertEqual(sequence2.count, 4)
    }

    func testResponseWithMinimalValues() throws {
        let data = HAData(testJsonString: """
        {
            "id": "76ce52a813c44fdf80ee36f926d62328"
        }
        """)
        let user = try HAResponseCurrentUser(data: data)
        XCTAssertEqual(user.id, "76ce52a813c44fdf80ee36f926d62328")
        XCTAssertEqual(user.name, nil)
        XCTAssertEqual(user.isOwner, false)
        XCTAssertEqual(user.isAdmin, false)
        XCTAssertEqual(user.credentials.count, 0)
        XCTAssertEqual(user.mfaModules.count, 0)
    }
}
