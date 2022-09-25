import Combine
import Foundation

public protocol State { }
public protocol Action { }

open class Redux<S: State> {
    public typealias Reducer = (_ action: Action, _ state: S) async throws -> S
    public typealias Completion = (State?, Error?) -> Void
    private var state: S
    private let reducer: Reducer
    private let subject = PassthroughSubject<S, Never>()
    init(state: S, reducer: @escaping Reducer) {
        self.reducer = reducer
        self.state = state
    }
    @discardableResult
    public func dispatch(action: Action) async throws -> State {
        state = try await reducer(action, state)
        subject.send(state)
        return state
    }
    public func trigger(action: Action, on queue: DispatchQueue = .main, completion: Completion? = nil) {
        Task {
            do {
                let state = try await dispatch(action: action)
                if let callback = completion {
                    queue.async {
                        callback(state, nil)
                    }
                }
            } catch {
                if let callback = completion {
                    queue.async {
                        callback(nil, error)
                    }
                }
            }
        }
    }
    public func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, S>, on object: Root) -> AnyCancellable {
        return subject.assign(to: keyPath, on: object)
    }
}
