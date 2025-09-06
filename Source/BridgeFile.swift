//
//  BridgeFile.swift
//  full_res_dlp
//
//  Created by Richard on 6/9/2025.
//

import Foundation

class PythonBridge {

    static let shared = PythonBridge()

    private init() {}

    func runPythonScript(withURL url: String, completion: @escaping (String?, String?) -> Void) {
        guard let scriptPath = Bundle.main.path(forResource: "debug_log_file_inc", ofType: "py") else {
            completion(nil, "Python script not found in bundle.")
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3") // system Python or path to Python framework
        process.arguments = [scriptPath]

        // If you want to inject URL dynamically:
        process.environment = ["TARGET_URL": url]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            completion(nil, "Failed to launch Python: \(error)")
            return
        }

        process.terminationHandler = { _ in
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8)
            let error = String(data: errorData, encoding: .utf8)
            completion(output, error)
        }
    }
}
