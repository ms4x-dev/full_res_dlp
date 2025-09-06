//
//  ContentView.swift
//  full_res_dlp
//
//  Created by Richard on 6/9/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var url: String = ""
    @State private var logText: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter URL", text: $url)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Download") {
                runPythonScript(url: url)
            }
            
            ScrollView {
                Text(logText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .frame(width: 500, height: 400)
    }
    
    func runPythonScript(url: String) {
        let pythonPath = "/usr/bin/python3" // adjust if using Python framework or venv
        let scriptPath = Bundle.main.path(forResource: "yt_download", ofType: "py")!
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = [scriptPath, url]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
        } catch {
            logText += "Failed to start Python script: \(error)\n"
            return
        }
        
        DispatchQueue.global().async {
            let handle = pipe.fileHandleForReading
            while let line = String(data: handle.availableData, encoding: .utf8), !line.isEmpty {
                DispatchQueue.main.async {
                    logText += line
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
