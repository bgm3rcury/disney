import XCTest
@testable import DisneyQueues

final class DisneyQueuesTests: XCTestCase {
    func testDecodesLandsAndTopLevelRides() throws {
        let json = """
        {
          "lands": [
            {
              "id": 1,
              "name": "Discoveryland",
              "rides": [
                {
                  "id": 101,
                  "name": "Star Tours",
                  "is_open": true,
                  "wait_time": 25,
                  "last_updated": "2026-08-12T10:15:00.000Z"
                }
              ]
            }
          ],
          "rides": [
            {
              "id": 202,
              "name": "Railroad",
              "is_open": false,
              "wait_time": 0,
              "last_updated": "2026-08-12T10:15:00.000Z"
            }
          ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            return ISO8601DateFormatter().date(from: value.replacingOccurrences(of: ".000Z", with: "Z"))!
        }

        let response = try decoder.decode(QueueTimesResponse.self, from: json)
        let attractions = response.attractions(for: .disneyland)

        XCTAssertEqual(attractions.count, 2)
        XCTAssertEqual(attractions[0].landName, "Discoveryland")
        XCTAssertEqual(attractions[1].landName, "Other")
        XCTAssertEqual(attractions[0].park, .disneyland)
    }

    func testCrowdLevels() {
        XCTAssertEqual(makeAttraction(waitTime: 10, isOpen: true).crowdLevel, .low)
        XCTAssertEqual(makeAttraction(waitTime: 25, isOpen: true).crowdLevel, .moderate)
        XCTAssertEqual(makeAttraction(waitTime: 55, isOpen: true).crowdLevel, .busy)
        XCTAssertEqual(makeAttraction(waitTime: 90, isOpen: true).crowdLevel, .veryBusy)
        XCTAssertEqual(makeAttraction(waitTime: 0, isOpen: false).crowdLevel, .closed)
    }

    private func makeAttraction(waitTime: Int, isOpen: Bool) -> Attraction {
        Attraction(
            id: "4-\(waitTime)-\(isOpen)",
            rideID: waitTime,
            park: .disneyland,
            landName: "Test",
            name: "Test Ride",
            isOpen: isOpen,
            waitTime: waitTime,
            lastUpdated: nil
        )
    }
}
