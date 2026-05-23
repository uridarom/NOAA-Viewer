import Foundation

struct LocalRisks {
    let tornado: Int
    let hail: Int
    let wind: Int
    let flood: Int?

    static let mock = LocalRisks(tornado: 5, hail: 15, wind: 10, flood: nil)
    static let zero = LocalRisks(tornado: 0, hail: 0, wind: 0, flood: nil)
}
