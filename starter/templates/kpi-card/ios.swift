import Foundation
import ChartCNMobile

let specData = try Data(contentsOf: URL(fileURLWithPath: "kpi-card/chartspec.json"))
let spec = try ChartSpecLoader.load(from: specData)

let rows: [ChartRow] = [
    ["metric": .string("MRR"), "value": .number(128400)],
    ["metric": .string("MRR"), "value": .number(132100)],
    ["metric": .string("MRR"), "value": .number(138900)]
]

let view = ChartCNView(spec: spec, rows: rows)
