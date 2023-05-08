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
        
        // Print the view controller name and path
        log.error("View controller did appear: \(self) at path: \(getPath())")
    }
    
    // This function returns the view controller's path in the view hierarchy
    func getPath() -> String {
        var path = ""
        if let parent {
            path += "\(parent.getPath()) > "
        }
        path += "\(type(of: self))"
        return path
    }
    
    // This function swaps the implementation of the original viewDidAppear with our custom implementation
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
