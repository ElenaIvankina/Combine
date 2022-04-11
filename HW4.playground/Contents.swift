import Foundation
import Combine

public func example(of description: String, action: () -> Void) {
    print ("\n-------- Example of: \(description)-------")
    action()
}

var cancellables: Set<AnyCancellable> = []

example(of: "API Client") {
    
    struct Film: Decodable {
      let id: Int
      let title: String
      let openingCrawl: String
      let director: String
      let producer: String
      let releaseDate: String
      let starships: [String]
      
      enum CodingKeys: String, CodingKey {
        case id = "episode_id"
        case title
        case openingCrawl = "opening_crawl"
        case director
        case producer
        case releaseDate = "release_date"
        case starships
      }
    }

    struct Films: Decodable {
      let count: Int
      let all: [Film]
      
      enum CodingKeys: String, CodingKey {
        case count
        case all = "results"
      }
    }

    struct Starship: Decodable {
      var name: String
      var model: String
      var manufacturer: String
      var cost: String
      var length: String
      var maximumSpeed: String
      var crewTotal: String
      var passengerTotal: String
      var cargoCapacity: String
      var consumables: String
      var hyperdriveRating: String
      var starshipClass: String
      var films: [String]
      
      enum CodingKeys: String, CodingKey {
        case name
        case model
        case manufacturer
        case cost = "cost_in_credits"
        case length
        case maximumSpeed = "max_atmosphering_speed"
        case crewTotal = "crew"
        case passengerTotal = "passengers"
        case cargoCapacity = "cargo_capacity"
        case consumables
        case hyperdriveRating = "hyperdrive_rating"
        case starshipClass = "starship_class"
        case films
      }
    }

    struct Starships: Decodable {
      var count: Int
      var all: [Starship]
      
      enum CodingKeys: String, CodingKey {
        case count
        case all = "results"
      }
    }

    enum NetworkError: LocalizedError {
            
         case unreachableAddress(url: URL)
         case invalidResponse
            
         var errorDescription: String? {
             switch self {
             case .unreachableAddress(let url): return "\(url.absoluteString) is unreachable"
             case .invalidResponse: return "Response with mistake"
             }
         }
    }

    enum Method {
            
            static let baseURL = URL(string: "https://swapi.dev/api/")!
            
            case film
            case starship (String)
        
            var url: URL {
            switch self {
            
                case .film:
                return Method.baseURL.appendingPathComponent("films/")
                    
                case .starship (let name):
                    
                var urlConstructor = URLComponents()
                    urlConstructor.scheme = "https"
                    urlConstructor.host = "swapi.dev"
                    urlConstructor.path = "/api/starships"
                    urlConstructor.queryItems = [
                    URLQueryItem(name: "search", value: name),
                            ]

                    return urlConstructor.url!
            }
            
        }
        
    }

    struct APIClient {
        
        private let decoder = JSONDecoder()
        private let queue = DispatchQueue(label: "APIClient", qos: .userInteractive, attributes: .concurrent)
        
        func getFilms ()-> AnyPublisher<Films, NetworkError> {
            URLSession.shared
                 .dataTaskPublisher(for: Method.film.url)
                 .receive(on: queue)
                 .map(\.data)
                 .decode(type: Films.self, decoder: decoder)
                 .mapError({ error -> NetworkError in
                    switch error {
                    case is URLError:
                      return NetworkError.unreachableAddress(url: Method.film.url)
                    default:
                      return NetworkError.invalidResponse
                    }
                 })
                 .eraseToAnyPublisher()
         }
        
        func getStarShip (name: String) -> AnyPublisher<Starships, NetworkError> {
            URLSession.shared
                 .dataTaskPublisher(for: Method.starship(name).url)
                 .breakpointOnError()
                 .receive(on: queue)
                 .map(\.data)
                 .decode(type: Starships.self, decoder: decoder)
                 .mapError({ error -> NetworkError in
                    switch error {
                    case is URLError:
                      print ("NetworkError")
                      return NetworkError.unreachableAddress(url: Method.starship(name).url)
                    default:
                      print ("OtherError")
                      return NetworkError.invalidResponse
                    }
                 })
                 .eraseToAnyPublisher()
         }
        
        
    }

    class ViewModelStarWars: ObservableObject {
        @Published var counter: Int = 0
        let aPIClient = APIClient()
    }

    let viewModelStarWars = ViewModelStarWars()
    
    let queue = DispatchQueue.main

    queue.schedule(
        after: queue.now,
        interval: .seconds(10)) {
        viewModelStarWars.counter += 1
    }
    .store(in: &cancellables)
    
    let subject = PassthroughSubject<Films, NetworkError>()
    
    let multicastedPublisherGetFilms = viewModelStarWars.aPIClient.getFilms()
        .multicast(subject: subject)
    
    viewModelStarWars.$counter
        .sink {
            if $0 > 0 {
                print ("Update data number \($0)")
            }

            viewModelStarWars.aPIClient.getFilms()
            .print("films publisher")
            .sink(receiveCompletion:
                    { print($0) },
                 receiveValue:
                    { print($0) })
            .store(in: &cancellables)

        }
        .store(in: &cancellables)
    
    multicastedPublisherGetFilms
        .sink(receiveCompletion:
                { _ in },
             receiveValue:
                { print("Sub1 \($0)") })
        .store(in: &cancellables)
    
    multicastedPublisherGetFilms
        .sink(receiveCompletion:
                { _ in },
             receiveValue:
                { print("Sub2 \($0)") })
        .store(in: &cancellables)
    
    
    multicastedPublisherGetFilms.connect()
    subject.send(Films(count: 0, all: []))



//    viewModelStarWars.aPIClient.getStarShip(name: "Star Destroyer")
//        .handleEvents(receiveSubscription:{_ in print("Network request will start")},
//                      receiveOutput: {_ in print("Network request data received")},
//                      receiveCompletion: {_ in print("Network request receive completion")},
//                      receiveCancel: {print("Network request cancelled")},
//                      receiveRequest: {_ in print("Network request get")})
//        .sink(receiveCompletion:
//                { print($0) },
//              receiveValue:
//                { print($0) })
//        .store(in: &cancellables)
    
}

