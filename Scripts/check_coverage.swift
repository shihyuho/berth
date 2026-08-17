#!/usr/bin/env swift

import Foundation

struct CoverageError: Error, CustomStringConvertible {
    let description: String
}

guard CommandLine.arguments.count == 3,
      let minimum = Double(CommandLine.arguments[2]) else {
    throw CoverageError(description: "usage: check_coverage.swift <coverage-json> <minimum-percent>")
}

let coverageURL = URL(fileURLWithPath: CommandLine.arguments[1])
let data = try Data(contentsOf: coverageURL)
guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let reports = root["data"] as? [[String: Any]],
      let report = reports.first,
      let files = report["files"] as? [[String: Any]] else {
    throw CoverageError(description: "coverage report has an unexpected format")
}

let coreFiles = files.filter { file in
    guard let filename = file["filename"] as? String else { return false }
    return filename.contains("/Sources/BerthCore/")
}

guard !coreFiles.isEmpty else {
    throw CoverageError(description: "coverage report contains no BerthCore source files")
}

let totals = try coreFiles.reduce(into: (covered: 0, count: 0)) { totals, file in
    guard let summary = file["summary"] as? [String: Any],
          let lines = summary["lines"] as? [String: Any],
          let covered = lines["covered"] as? Int,
          let count = lines["count"] as? Int else {
        throw CoverageError(description: "coverage report is missing line totals")
    }
    totals.covered += covered
    totals.count += count
}

guard totals.count > 0 else {
    throw CoverageError(description: "BerthCore has no executable lines")
}

let percentage = Double(totals.covered) / Double(totals.count) * 100
print(String(format: "BerthCore line coverage: %.2f%% (%d/%d)", percentage, totals.covered, totals.count))

guard percentage >= minimum else {
    throw CoverageError(
        description: String(format: "BerthCore line coverage %.2f%% is below %.2f%%", percentage, minimum)
    )
}
