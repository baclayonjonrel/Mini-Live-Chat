//
//  SummaryMaker.swift
//  Mini Live Chat
//
//  Created by Jonrel Baclayon on 8/22/25.
//

import Foundation

class SummaryMaker {
    static let shared = SummaryMaker()
    
    func summarizeSentences(_ sentences: [String], completion: @escaping (String?) -> Void) {
        let apiKey = "CHANGE API KEY"
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)")!
        
        // Join sentences into one block of text
        let textToSummarize = sentences.joined(separator: " ")

        let json: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": """
        Summarize the following meeting transcript into a concise summary. 
        - Highlight key points.
        - Extract any action items or TODOs and label them clearly.
        - Return only the summary and the TODO list in a clear format, e.g.:

        Summary:
        1. ...
        2. ...

        TODOs:
        - ...
        - ...

        Transcript:
        \(textToSummarize)
        """]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = result["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let summary = parts.first?["text"] as? String else {
                completion(nil)
                return
            }
            completion(summary.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
}

