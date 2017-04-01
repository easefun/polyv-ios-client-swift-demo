//
//  UploadDemoViewController.swift
//  polyv-ios-client-swift-demo
//
//  Created by R0uter on 2017/3/31.
//  Copyright © 2017年 R0uter. All rights reserved.
//

import UIKit
import MobileCoreServices
import AssetsLibrary
import AVFoundation

let PLVRemoteURLDefaultsKey = "PLVRemoteURL"

class UploadDemoViewController:UIViewController {
    var assetsLibrary = ALAssetsLibrary()
    lazy var videoPlayer:SkinVideoViewController = {
        let width = self.view.bounds.size.width
        let vp:SkinVideoViewController = SkinVideoViewController(frame: CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y, width: width, height: width*(9.0/16.0)))
        vp.dimissCompleteBlock = {
            vp.stop()
        }
        return vp
    }()
    var vid = ""
    
    @IBOutlet weak var imageOverlay:UIView!
    @IBOutlet weak var imageView:UIImageView!
    @IBOutlet weak var urlTextView:UITextView!
    @IBOutlet weak var statusLabel:UILabel!
    @IBOutlet weak var progressBar:UIProgressView!
    @IBOutlet weak var chooseFileButton:UIButton!
 
    override func viewDidLoad() {
        super.viewDidLoad()
        imageOverlay.isHidden = true
        progressBar.progress = 0
        UserDefaults.standard.register(defaults: [PLVRemoteURLDefaultsKey:"https://upload.polyv.net:1081/files/"])
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.numberOfTapsRequired = 1
        urlTextView.addGestureRecognizer(singleTap)
    }
    
    @IBAction func chooseFile (_ sender:Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    @IBAction func closeButtonAction(_ sender:Any) {
        self.dismiss(animated: true, completion: nil)
    }
    func handleSingleTap () {
        if let video = PolyvSettings.getVideo(vid) {
            if video.available() {
                videoPlayer.showInWindow()
                videoPlayer.setVid(vid, level: .standard)
            } else {
                let alert = UIAlertView(title: "提示", message: "视频还没有准备好", delegate: nil, cancelButtonTitle: "好")
                alert.show()
            }
        }
        
        
    }
}
//MARK:UIImagePickerDelegate Methods
extension UploadDemoViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let videoUrl = info[UIImagePickerControllerMediaURL] as! URL
        let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory().appending("temp.mov"))
        
        let hudView = UIView(frame: CGRect(x: 75, y: 155, width: 170, height: 170))
        hudView.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.5)
        hudView.clipsToBounds = true
        hudView.layer.cornerRadius = 10.0
        
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicatorView.frame = CGRect(x: 65, y: 40, width: activityIndicatorView.bounds.size.width, height: activityIndicatorView.bounds.size.width)
        hudView.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()
        
        let captionLabel = UILabel(frame: CGRect(x: 20, y: 115, width: 130, height: 22))
        captionLabel.backgroundColor = UIColor.clear
        captionLabel.textColor = UIColor.white
        captionLabel.adjustsFontSizeToFitWidth = true
        captionLabel.textAlignment = .center
        captionLabel.text = "正在压缩视频..."
        hudView.addSubview(captionLabel)
        picker.view.addSubview(hudView)
        
        self.convertVideoToLowQuailty(withInputURL: videoUrl, outputURL: outputUrl) {
            DispatchQueue.main.async {
                hudView.removeFromSuperview()
            }
            if $0.status == .completed {
                self.urlTextView.text = ""
                self.imageView = nil
                self.dismiss(animated: true) {
                    let type = info[UIImagePickerControllerMediaType]
                    let typeDescription = UTTypeCopyDeclaration(type as! CFString)
                    let text = String(format: "Uploading %@...", typeDescription as! CVarArg)
                    self.statusLabel.text = text
                    self.imageOverlay.isHidden = false
                    self.chooseFileButton.isEnabled = false
                    
                }
            }else {
                LogPrint("error!")
            }
        }
    }
    /**压缩视频大小*/
    func convertVideoToLowQuailty(withInputURL inputURL:URL, outputURL:URL, handler:@escaping (AVAssetExportSession)->()) {
        try? FileManager.default.removeItem(at: outputURL)
        let asset = AVURLAsset(url: inputURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality)
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = AVFileTypeQuickTimeMovie
        exportSession?.exportAsynchronously {
            handler(exportSession!)
        }
    }
    /**使用文件地址上传*/
    var endpoint:String {return UserDefaults.standard.value(forKey: PLVRemoteURLDefaultsKey) as! String}
    var progressBlock:PLVUploadProgressBlock {
        return {
            var progress = Float($0)/Float($1)
            if progress.isNaN {progress = 0.0}
            DispatchQueue.main.async {
                self.progressBar.progress = progress
            }
        }
    }
    
    var failureBlock:PLVUploadFailureBlock {
        return { e in
            
            DispatchQueue.main.async {
                LogPrint("Failed to upload file due to:\(String(describing: e?.localizedDescription))")
                self.chooseFileButton.isEnabled = true
                var text = self.urlTextView.text
                text = text?.appending("\n\(String(describing: e?.localizedDescription))")
                self.urlTextView.text = text
                self.statusLabel.text = "Failed!"
                UIAlertView(title: "Error", message: e?.localizedDescription, delegate: nil, cancelButtonTitle: "好").show()
            }
        }
    }
    var resultBlock:PLVUploadResultBlock {
        return { vid in
            DispatchQueue.main.async {
                self.chooseFileButton.isEnabled = true
                self.imageOverlay.isHidden = true
                self.imageView.alpha = 1
                
                self.urlTextView.text = "点击播放 \(String(describing: vid))"
                self.vid = vid!
            }
        }
    }
    func uploadVideo(fromURL url:URL) {
        let uploadData = PLVData(data: try! Data(contentsOf: url))
        let upload = PLVResumableUpload(url: endpoint, data: uploadData, fingerprint: url.absoluteString)
        let extraInfo = [
            "ext":"mov",
            "cataid":"1357359024647",
            "title":"polyvsdk",
            "desc":"polyvsdk upload demo video" ,
        ]
        upload?.setExtraInfo(extraInfo as! NSMutableDictionary)
        upload?.progressBlock = progressBlock
        upload?.resultBlock = resultBlock
        upload?.failureBlock = failureBlock
        
        upload?.start()
    }
    
    /**Asset上传**/
    func uploadVideo(fromAsset info:NSDictionary) {
        
    }
    
}

//MARK:页面旋转
extension UploadDemoViewController {
    override var shouldAutorotate: Bool {
        return false
    }
    override var supportedInterfaceOrientations:UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation:UIInterfaceOrientation {
        return .portrait
    }
    
}
