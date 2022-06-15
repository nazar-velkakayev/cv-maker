//
//  CustomExtensions.swift
//  Belli-CV
//
//  Created by Belli's MacBook on 11/06/2022.
//

import Foundation
import UIKit
import SwiftUI

// MARK: - Removes charecters from string
extension String {
    func toLengthOf(length:Int) -> String {
        if length <= 0 {
            return self
        } else if let to = self.index(self.startIndex, offsetBy: length, limitedBy: self.endIndex) {
            return self.substring(from: to)
        } else {
            return ""
        }
    }
}

// MARK: - Saves Date to @AppStorage
extension Date: RawRepresentable {
    private static let formatter = ISO8601DateFormatter()
    
    public var rawValue: String {
        Date.formatter.string(from: self)
    }
    
    public init?(rawValue: String) {
        self = Date.formatter.date(from: rawValue) ?? Date()
    }
}

// MARK: - Saves array in @AppStorage
extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

//MARK: - Extracting View's height and width with the help of Hosting Controller and ScrollView ( From KAVSOFT )

extension View{
    func convertToScrollView<Content: View>(@ViewBuilder content: @escaping ()-> Content) -> UIScrollView{
        let scrollView = UIScrollView()
        
        // Converting SwiftUI View to UIKit View
        let hostingController = UIHostingController(rootView: content()).view!
        hostingController.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints
        let constraints = [
            hostingController.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            // Width anchor
            hostingController.widthAnchor.constraint(equalToConstant: screenBounds().width)

        ]
        
        scrollView.addSubview(hostingController)
        scrollView.addConstraints(constraints)
        scrollView.layoutIfNeeded()
        
        return scrollView
    }
    
    func screenBounds()->CGRect{
        return UIScreen.main.bounds
    }
    
    //MARK: Export to PDF
    //MARK: Complition Handler will send status and URL
    func exportToPDF<Content: View>(@ViewBuilder content: @escaping ()-> Content, complition: @escaping (Bool, URL?) -> ()){
        
        guard let documentDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else{
            print("error while exporting data")
            return
        }
        // To generate new pdf file
        let outputFileURL = documentDirectory.appendingPathComponent("MYCV-\(UUID().uuidString).pdf")
        
        //MARK: Pdf View
        let pdfView = convertToScrollView {
            content()
        }
        pdfView.tag = 1009
        
        let size = pdfView.contentSize
        
        // removing safe area top value
        pdfView.frame = CGRect(x: 0, y: getSafeArea().top, width: size.width, height: size.height)
        
        //MARK: Attaching to Root View and rendering PDF
        getRootController().view.insertSubview(pdfView, at: 0)
        
        //MARK: Rendering PDF
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        do {
            try renderer.writePDF(to: outputFileURL, withActions: { context in
                
                context.beginPage()
                pdfView.layer.render(in: context.cgContext)
                
                
            })
            complition(true, outputFileURL)
        } catch {
            complition(false, nil)
            print("error rendering pdf: \(error)")
        }
        
        //MARK: Removing the added view
        getRootController().view.subviews.forEach { view in
            if view.tag == 1009{
                print("removed")
                view.removeFromSuperview()
            }
        }
    }
    
    func getRootController()-> UIViewController{
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else{
            print("error while getting screen")
            return .init()
        }
        
        guard let root = screen.windows.first?.rootViewController else{
            print("error getting root")
            return .init()
        }
        return root
    }
    
    func getSafeArea()-> UIEdgeInsets{
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else{
            print("error while getting screen")
            return .zero
        }
        
        guard let safeArea = screen.windows.first?.safeAreaInsets else{
            print("error getting root")
            return .zero
        }
        return safeArea
    }
}
