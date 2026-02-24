import Foundation
import ChartCNMobile

let specData = try Data(contentsOf: URL(fileURLWithPath: "comparison-bar/chartspec.json"))
let spec = try ChartSpecLoader.load(from: specData)

let rows: [ChartRow] = [
    ["segment": .string("Organic"), "conversion_rate": .number(41.2)],
    ["segment": .string("Paid"), "conversion_rate": .number(33.9)],
    ["segment": .string("Referral"), "conversion_rate": .number(48.7)],
    ["segment": .string("Email"), "conversion_rate": .number(44.6)]
]

let view = ChartCNView(spec: spec, rows: rows)
