//
//  ViewController.swift
//  VisionDemoApp
//
//  Created by 李仲澄 on 2018/10/16.
//  Copyright © 2018 zhgchgli. All rights reserved.
//

import UIKit
import Vision
import Kingfisher
class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewConstraints: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        reconizeFace(self)
    }

    @IBAction func reconizeFace(_ sender: Any) {
        //圖片先行裁切壓縮使其符合imageView容器，避免留空錯位
        let ratio = UIScreen.main.bounds.size.width
        let sourceImage = UIImage(named: "Demo2")?.kf.resize(to: CGSize(width: ratio, height: CGFloat.leastNonzeroMagnitude), for: .aspectFill)
        
        imageView.contentMode = .redraw
        imageView.image = sourceImage
        imageViewConstraints.constant = (ratio - (sourceImage?.size.height ?? 0))
        imageView.layoutIfNeeded()
        imageView.sizeToFit()
        
        guard let image = sourceImage,let ciImage = CIImage(image: image) else {
            return
        }
        imageView.subviews.forEach { (subView) in
            subView.removeFromSuperview()
        }
        if #available(iOS 11.0, *) {
            let completionHandle: VNRequestCompletionHandler = { request, error in
                if let faceObservations = request.results as? [VNFaceObservation] {
                    DispatchQueue.main.async {
                        //操作UIVIEW，切回主執行緒
                        let size = self.imageView.frame.size
                        
                        faceObservations.forEach({ (faceObservation) in
                            //坐標系轉換
                            let translate = CGAffineTransform.identity.scaledBy(x: size.width, y: size.height)
                            let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -size.height)
                            let transRect =  faceObservation.boundingBox.applying(translate).applying(transform)
                            
                            let markerView = UIView(frame: transRect)
                            markerView.backgroundColor = UIColor.init(red: 0/255, green: 255/255, blue: 0/255, alpha: 0.3)
                            self.imageView.addSubview(markerView)
                        })
                    }
                } else {
                    print("未偵測到任何臉")
                }
            }
            let baseRequest = VNDetectFaceRectanglesRequest(completionHandler: completionHandle)
            let faceHandle = VNImageRequestHandler(ciImage: ciImage, options: [:])
            DispatchQueue.global().async {
                //辨識需要時間，所以放入背景子執行緒執行，避免當前畫面卡住
                do{
                    try faceHandle.perform([baseRequest])
                }catch{
                    print("Throws：\(error)")
                }
            }
        } else {
            //
            print("不支援")
        }
    }
    
    @IBAction func crop(_ sender: Any) {
        imageView.subviews.forEach { (subView) in
            subView.removeFromSuperview()
        }
        let ratio = UIScreen.main.bounds.size.width
        let sourceImage = UIImage(named: "Demo")
        
        imageView.contentMode = .scaleAspectFill
        imageView.image = sourceImage
        imageViewConstraints.constant = 0
        imageView.layoutIfNeeded()
        imageView.sizeToFit()
        
        if let image = sourceImage,#available(iOS 11.0, *),let ciImage = CIImage(image: image) {
            let completionHandle: VNRequestCompletionHandler = { request, error in
                if request.results?.count == 1,let faceObservation = request.results?.first as? VNFaceObservation {
                    //ㄧ張臉
                    let size = CGSize(width: ratio, height: ratio)
                    
                    let translate = CGAffineTransform.identity.scaledBy(x: size.width, y: size.height)
                    let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -size.height)
                    let finalRect =  faceObservation.boundingBox.applying(translate).applying(transform)
                    
                    let center = CGPoint(x: (finalRect.origin.x + finalRect.width/2 - size.width/2), y: (finalRect.origin.y + finalRect.height/2 - size.height/2))
                    
                    
                    let newImage = image.kf.resize(to: size, for: .aspectFill).kf.crop(to: size, anchorOn: center)
                    
                    DispatchQueue.main.async {
                        //操作UIVIEW，切回主執行緒
                        self.imageView.image = newImage
                    }
                } else {
                    print("偵測到多張臉或沒有偵測到臉")
                }
            }
            let baseRequest = VNDetectFaceRectanglesRequest(completionHandler: completionHandle)
            let faceHandle = VNImageRequestHandler(ciImage: ciImage, options: [:])
            DispatchQueue.global().async {
                do{
                    try faceHandle.perform([baseRequest])
                }catch{
                    print("Throws：\(error)")
                }
            }
        } else {
            print("不支援")
        }
    }
    
}
