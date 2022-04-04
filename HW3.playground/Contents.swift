
import Foundation
import Combine

//1. Создайте первый издатель, производный от Subject, который испускает строки.
//
//2. Используйте .collect() со стратегией .byTime для группировки данных через каждые 0.5 секунд.
//
//3. Преобразуйте каждое значение в Unicode.Scalar, затем в Character, а затем превратите весь массив в строку с помощью .map().
//
//4. Создайте второй издатель, производный от Subject, который измеряет интервалы между каждым символом. Если интервал превышает 0,9 секунды, сопоставьте это значение с эмодзи. В противном случае сопоставьте его с пустой строкой.
//
//5. Окончательный издатель — это слияние двух предыдущих издателей строк и эмодзи. Отфильтруйте пустые строки для лучшего отображения.
//
//6. Результат выведите в консоль.

let queue = DispatchQueue(label: "Collect")
let stringPublisher = PassthroughSubject<String, Never>()

let startDate = Date()

let deltaFormatter: NumberFormatter = {
let format = NumberFormatter()
    format.negativePrefix = ""
    format.minimumFractionDigits = 2
    format.maximumFractionDigits = 2
    return format
}()

var deltaTime: String {
return deltaFormatter.string(for: Date().timeIntervalSince(startDate))!
}

let deltaTimePublisher = PassthroughSubject<String, Never>()

queue.asyncAfter(deadline: .now() + 0.1, execute: { stringPublisher.send("ABC")})
                                                                            
queue.asyncAfter(deadline: .now() + 0.2, execute: {stringPublisher.send("D") })
                                                                            
queue.asyncAfter(deadline: .now() + 1, execute: { stringPublisher.send("EF")})
                                                                            
queue.asyncAfter(deadline: .now() + 3.1, execute: {stringPublisher.send("G") })
                                                                            
queue.asyncAfter(deadline: .now() + 3.2, execute: { stringPublisher.send("I")})

let subscriptionStringPublisher = stringPublisher
    .collect(.byTime(queue, .seconds(0.5)))
    .map { array in
        array.reduce(String("")) { result, value in
                result + value
        }
    }
    .map {string in
        Array(string)
    }
    .map {array in
        array.compactMap {
            Unicode.Scalar(String($0))
        }
    }
    .map {array in
        array.compactMap {
            Character($0)
        }
    }
    .map { array in
        array.reduce(String("")) { result, value in
                result + String(value)
        }
    }
    .sink(receiveCompletion: { completion in
            print("received the completion", String(describing: completion)) },
          receiveValue: { _ in
            deltaTimePublisher.send(deltaTime)
          })

let subscriptionZipWithDeltaPublisher = stringPublisher
    .collect(.byTime(queue, .seconds(0.5)))
    .map { array in
        array.reduce(String("")) { result, value in
                result + value
        }
    }
    .zip(deltaTimePublisher)
    .sink(receiveValue: { value1, value2 in
        guard let deltaDouble = Double (value2) else {return}
            if deltaDouble >= 0.9 {
                print (value1 + " " + value2 + " 😒 ")
            } else if deltaDouble < 0.9 {
                print (value1 + " " + value2 + " 😀 ")
            }
    })





                                                                            





