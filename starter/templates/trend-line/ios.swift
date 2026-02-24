import Foundation
import ChartCNMobile

let specData = try Data(contentsOf: URL(fileURLWithPath: "trend-line/chartspec.json"))
let spec = try ChartSpecLoader.load(from: specData)

let rows: [ChartRow] = [
    ["day": .string("2026-02-18"), "active_users": .number(1120)],
    ["day": .string("2026-02-19"), "active_users": .number(1195)],
    ["day": .string("2026-02-20"), "active_users": .number(1230)],
    ["day": .string("2026-02-21"), "active_users": .number(1278)],
    ["day": .string("2026-02-22"), "active_users": .number(1326)],
    ["day": .string("2026-02-23"), "active_users": .number(1368)],
    ["day": .string("2026-02-24"), "active_users": .number(1412)]
]

let view = ChartCNView(spec: spec, rows: rows)
