import XCTest
@testable import Redux

extension Int: State {
    // so any integer can be a state now!
}

extension Bool: Action {
    // so the boolean can be an action now!
}

class MyObj: NSObject {
    @objc var value = 0
}

final class ReduxTests: XCTestCase {
    func testDispatch() throws {
        let reduxer = Redux(state: 0) { action, state async throws -> Int in
            guard let action = action as? Bool else {
                return 0
            }
            let inc = action ? 1 : -1
            return state + inc
        }
        let obj = MyObj()
        let assignment = reduxer.assign(to: \.value, on: obj)
        let exp = expectation(description: "dispatch")
        Task {
            do {
                var state = try await reduxer.dispatch(action: true)
                XCTAssertEqual(state as? Int, 1)
                XCTAssertEqual(obj.value, 1)
                state = try await reduxer.dispatch(action: false)
                XCTAssertEqual(state as? Int, 0)
                XCTAssertEqual(obj.value, 0)
                exp.fulfill()
            } catch {
                XCTFail("\(error)")
            }
        }
        wait(for: [exp], timeout: 3)
        assignment.cancel()
    }
    func testTrigger() throws {
        let reduxer = Redux(state: 0) { action, state async throws -> Int in
            guard let action = action as? Bool else {
                return 0
            }
            let inc = action ? 1 : -1
            return state + inc
        }
        let obj = MyObj()
        let assignment = reduxer.assign(to: \.value, on: obj)
        let exp = expectation(description: "trigger")
        reduxer.trigger(action: true) { state, error in
            XCTAssertNil(error)
            XCTAssertEqual(state as? Int, 1)
            XCTAssertEqual(obj.value, 1)
            reduxer.trigger(action: false) { state, error in
                XCTAssertNil(error)
                XCTAssertEqual(state as? Int, 0)
                XCTAssertEqual(obj.value, 0)
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 3)
        assignment.cancel()
    }
}
