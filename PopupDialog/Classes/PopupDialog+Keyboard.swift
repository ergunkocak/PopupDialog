//
//  PopupDialog+Keyboard.swift
//
//  Copyright (c) 2016 Orderella Ltd. (http://orderella.co.uk)
//  Author - Martin Wildfeuer (http://www.mwfire.de)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import UIKit

/// This extension is designed to handle dialog positioning
/// if a keyboard is displayed while the popup is on top
extension PopupDialog {

    // MARK: - Keyboard & orientation observers

    /*! Add obserservers for UIKeyboard notifications */
    internal func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged),
                                                         name: UIDevice.orientationDidChangeNotification,
                                                         object: nil)

        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(keyboardWillShow),
                                                         name: UIResponder.keyboardWillShowNotification,
                                                         object: nil)

        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(keyboardWillHide),
                                                         name: UIResponder.keyboardWillHideNotification,
                                                         object: nil)

        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(keyboardWillChangeFrame),
                                                         name: UIResponder.keyboardWillChangeFrameNotification,
                                                         object: nil)
    }

    /*! Remove observers */
    internal func removeObservers() {
        NotificationCenter.default.removeObserver(self,
                                                            name: UIDevice.orientationDidChangeNotification,
                                                            object: nil)

        NotificationCenter.default.removeObserver(self,
                                                            name: UIResponder.keyboardWillShowNotification,
                                                            object: nil)

        NotificationCenter.default.removeObserver(self,
                                                            name: UIResponder.keyboardWillHideNotification,
                                                            object: nil)

        NotificationCenter.default.removeObserver(self,
                                                            name: UIResponder.keyboardWillChangeFrameNotification,
                                                            object: nil)
    }

    // MARK: - Actions

    /*!
     Keyboard will show notification listener
     - parameter notification: NSNotification
     */
    @objc fileprivate func keyboardWillShow(_ notification: Notification) {
        guard isTopAndVisible else { return }
        keyboardShown = true
        centerPopup()
    }

    /*!
     Keyboard will hide notification listener
     - parameter notification: NSNotification
     */
    @objc fileprivate func keyboardWillHide(_ notification: Notification) {
        guard isTopAndVisible else { return }
        keyboardShown = false
        centerPopup()
    }

    /*!
     Keyboard will change frame notification listener
     - parameter notification: NSNotification
     */
    @objc fileprivate func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardRect = (notification as NSNotification).userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        keyboardHeight = keyboardRect.cgRectValue.height
    }

    /*!
     Listen to orientation changes
     - parameter notification: NSNotification
     */
    @objc fileprivate func orientationChanged(_ notification: Notification) {
        if keyboardShown { centerPopup() }
    }

    func centerPopup() {

        // Make sure keyboard should reposition on keayboard notifications
        guard keyboardShiftsView else { return }

        // Make sure a valid keyboard height is available
        guard let keyboardHeight = keyboardHeight else { return }

        let viewHeight = popupContainerView.container.bounds.size.height
        let statusBarHeight: CGFloat
        let bottomBarHeight: CGFloat
        if #available(iOS 11.0, *) {
            statusBarHeight = popupContainerView.safeAreaInsets.top
            bottomBarHeight = popupContainerView.safeAreaInsets.bottom
        } else {
            // Fallback on earlier versions
            statusBarHeight = 20
            bottomBarHeight = 0
        }
        let safeInsetHeight = statusBarHeight + bottomBarHeight
        let screenHeight = UIScreen.main.bounds.size.height
        let visibleAreaHeight = screenHeight - safeInsetHeight
        let unUsedHeight = visibleAreaHeight - viewHeight
        //        print("screenHeight:\(screenHeight) safeInsetHeight: \(safeInsetHeight) visibleAreaHeight:\(visibleAreaHeight) keyboardHeight: \(keyboardHeight)")
        //        print("viewHeight: \(viewHeight) unUsedHeight: \(unUsedHeight)")

        popupContainerView.topConstraint?.isActive = false
        popupContainerView.topConstraint = nil
        popupContainerView.centerYConstraint?.isActive = false
        popupContainerView.centerYConstraint = nil

        if keyboardHeight < unUsedHeight {
            // Calculate new center of shadow background
            let popupCenter = keyboardShown ? keyboardHeight / -2 : 0

            // Reposition and animate
            popupContainerView.centerYConstraint = NSLayoutConstraint(item: popupContainerView.shadowContainer, attribute: .centerY, relatedBy: .equal, toItem: popupContainerView, attribute: .centerY, multiplier: 1, constant: popupCenter)
            popupContainerView.centerYConstraint!.isActive = true

        } else {
            // Calculate new center of shadow background
            let popupCenter = keyboardShown ? unUsedHeight / -2 : 0

            // Reposition and animate
            popupContainerView.topConstraint = NSLayoutConstraint(item: popupContainerView.container, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: popupContainerView, attribute: .top, multiplier: 1, constant: statusBarHeight)
            popupContainerView.topConstraint!.isActive = true
        }

        popupContainerView.pv_layoutIfNeededAnimated()
    }
}
