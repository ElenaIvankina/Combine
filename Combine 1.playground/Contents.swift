import Combine
import Foundation

public func example(of description: String, action: () -> Void) {
    print("\n------ Example of:", description, "------")
    action()
}

var cancellables: Set<AnyCancellable> = []

example(of: "Publisher") {
    
    let publisher = PassthroughSubject<Int, Never>()
    
        publisher
        .sink { _ in
            print("Completed")
        } receiveValue: { value in
            let v = value * 3
            print(v)
        }
        .store(in: &cancellables)
    
    publisher.send(1)
    publisher.send(1)
    publisher.send(2)
    publisher.send(3)
    publisher.send(5)
    
    publisher.send(completion: .finished)
    
}

example(of: "Custom Subscriber") {
  
  final class StringSubscriber: Subscriber {
    typealias Input = String
    typealias Failure = Never

    func receive(subscription: Subscription) {
      subscription.request(.unlimited)
    }
    
    func receive(_ input: String) -> Subscribers.Demand {
      print("Received value", input)
      return .none
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
      print("Received completion", completion)
    }
  }
  
    let subscriber = StringSubscriber()

    let subject = CurrentValueSubject<String, Never>("First value")
    
    subject.subscribe(subscriber)
    
    subject
    .sink { _ in
        print("Completed")
    } receiveValue: { value in
        let v = "_" + value + "_"
        print(v)
    }
    .store(in: &cancellables)
        
    subject.send("Second value")
    subject.send("Third value")
    subject.send(completion: .finished)
}


