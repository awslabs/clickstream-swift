//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension JsonObject {
    func toJsonString() -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.sortedKeys])
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            print("Error serializing dictionary to JSON: \(error.localizedDescription)")
        }
        return ""
    }

    func toPrettierJsonString() -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.sortedKeys, .prettyPrinted])
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            print("Error serializing dictionary to JSON: \(error.localizedDescription)")
        }
        return ""
    }
}
