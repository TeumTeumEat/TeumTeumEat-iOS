//
//  UIApplication+TopViewController.swift
//  TeumTeumEat
//

import UIKit

extension UIApplication {
    /// 현재 화면 맨 위의 ViewController (UIKit 화면을 직접 띄울 때 사용: 광고, 공유 시트 등)
    func topViewController(from base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController

        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }
        return root
    }
}
