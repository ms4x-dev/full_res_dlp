//
//  BridgeFile.swift
//  full_res_dlp
//
//  Created by Richard on 6/9/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var url: String = ""
    @State private var logText: String = ""
    @State private var isDownloading: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Enter URL to download:")
                .font(.headline)

            TextField("URL", text: $url)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.trailing)

            Button(action: startDownload) {
                HStack {
                    Text(isDownloading ? "Downloading..." : "Start Download")
                    if isDownloading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
            }
            .disabled(isDownloading || url.isEmpty)

            ScrollView {
                Text(logText)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .border(Color.gray)
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }

    func startDownload() {
        guard !url.isEmpty else { return }
        isDownloading = true
        logText = ""

        // Path to Python executable
        let pythonPath = "/Library/Frameworks/Python.framework/Versions/3.13/bin/python3"
        // Path to your yt_download.py
        let scriptPath = Bundle.main.path(forResource: "yt_download", ofType: "py") ?? ""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [scriptPath, url]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let handle = pipe.fileHandleForReading
        handle.readabilityHandler = { fileHandle in
            if let line = String(data: fileHandle.availableData, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.logText += line
                }
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try process.run()
                process.waitUntilExit()
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.logText += "\nDownload finished with exit code \(process.terminationStatus)\n"
                }
            } catch {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.logText += "\nFailed to start process: \(error.localizedDescription)\n"
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
