
import Combine
import Foundation

 public func example(of description: String, action: () -> Void) {
     print("\n------ Example of:", description, "------")
     action()
 }

/*
 1. Создайте пример, который публикует коллекцию чисел от 1 до 100, и используйте операторы фильтрации, чтобы выполнить следующие действия:

Пропустите первые 50 значений, выданных вышестоящим издателем.
Возьмите следующие 20 значений после этих первых 50.
Берите только чётные числа.
2. Создайте пример, который собирает коллекцию строк, преобразует её в коллекцию чисел и вычисляет среднее арифметическое этих значений.
*/

 var cancellables: Set<AnyCancellable> = []

 example(of: "point 1") {

    let publisher = (1...100).publisher

         publisher
         .dropFirst(50)
         .prefix(20)
         .filter { $0 % 2 == 0}
         .sink { _ in
             print("Completed")
         } receiveValue: { value in
             print(value)
         }
         .store(in: &cancellables)


 }

example(of: "point 2") {

   let publisher = ["1", "2", "3", "4", "5", "6"].publisher
   var counter = 0

        publisher
        .compactMap {Int($0)}
        .scan(0) { latest, current in
                counter += 1
                return latest + current
        }
        .last()
        .sink { _ in
            print("Completed")
        } receiveValue: { value in
            let average = Double(value)/Double(counter)
            print(String(format: "%.2f", average))
        }
        .store(in: &cancellables)

}
