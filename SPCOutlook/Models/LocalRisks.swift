import Foundation

struct LocalRisks {
    let tornado: Int
    let tornadoSignificant: Bool
    let hail: Int
    let hailSignificant: Bool
    let wind: Int
    let windSignificant: Bool
    let flood: Int?

    static let mock = LocalRisks(tornado: 5, tornadoSignificant: false,
                                 hail: 15, hailSignificant: false,
                                 wind: 10, windSignificant: false,
                                 flood: nil)
    static let zero = LocalRisks(tornado: 0, tornadoSignificant: false,
                                 hail: 0, hailSignificant: false,
                                 wind: 0, windSignificant: false,
                                 flood: nil)
}
