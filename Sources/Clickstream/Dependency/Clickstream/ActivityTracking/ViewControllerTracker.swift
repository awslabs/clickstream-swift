//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(UIKit)
    import UIKit
#endif

private var hasSwizzled = false

extension UIViewController: ClickstreamLogger {}

extension UIViewController {
    @objc func swizzled_viewDidAppear(_ animated: Bool) {
        // Call the original implementation of viewDidAppear
        swizzled_viewDidAppear(animated)

        let name = type(of: self)
        let path = getPath()
        let path1 = getPath1()
        log.error("path1: \(path1)")
        log.error("View controller did appear: \(name) at path: \(path)")
    }

    func getPath() -> String {
        var path = ""
        if let parent {
            path += "\(parent.getPath())/"
        }
        path += "\(type(of: self))"
        return path
    }

    func getPath1() -> String {
        if let navController = navigationController {
            for (index, viewController) in navController.viewControllers.enumerated() {
                if viewController == self {
                    return "\(index)"
                }
            }
            return ""
        } else {
            return ""
        }
    }

    static func swizzle() {
        guard !hasSwizzled else { return }
        let originalSelector = #selector(viewDidAppear(_:))
        let swizzledSelector = #selector(swizzled_viewDidAppear(_:))

        let originalMethod = class_getInstanceMethod(self, originalSelector)!
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)!

        method_exchangeImplementations(originalMethod, swizzledMethod)

        hasSwizzled = true
    }
}
