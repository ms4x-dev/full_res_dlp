import SwiftUI

struct ContentView: View {
    @State private var logText = ""

    var body: some View {
        VStack {
            TextEditor(text: $logText)
                .frame(height: 400)
                .border(Color.gray)
            
            Button("Download Video") {
                PythonBridge.shared.runPythonScript(withURL: "https://www.mywebsite.com/watch?v=ZyWelvEP_CQ") { output, error in
                    DispatchQueue.main.async {
                        if let output = output {
                            logText += output + "\n"
                        }
                        if let error = error {
                            logText += "Error: \(error)\n"
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
