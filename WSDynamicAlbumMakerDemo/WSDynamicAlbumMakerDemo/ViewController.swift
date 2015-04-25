//
//  ViewController.swift
//  WSDynamicAlbumMakerDemo
//
//  Created by ennrd on 4/25/15.
//  Copyright (c) 2015 ws. All rights reserved.
//

import UIKit
import MediaPlayer
import CTAssetsPickerController
import MBProgressHUD


class ViewController: UIViewController{

    
    var alAssetsPicked : [AnyObject]!
    let player = MPMoviePlayerController()

    @IBOutlet weak var videoPlayerCanvas: UIView!

    
    @IBAction func pickPhotosAndMake(sender: UIBarButtonItem) {
        
        let photoPicker = CTAssetsPickerController()
        photoPicker.assetsFilter = ALAssetsFilter.allPhotos()
        photoPicker.delegate = self
        
        self.presentViewController(photoPicker, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        player.scalingMode = .AspectFit
        player.fullscreen = false
        player.controlStyle = MPMovieControlStyle.Embedded
        player.shouldAutoplay = false
    }

    
    override func viewWillAppear(animated: Bool) {
        player.view.frame = CGRectMake(0, 0, self.videoPlayerCanvas.frame.size.width, self.videoPlayerCanvas.frame.size.height)
        self.videoPlayerCanvas.addSubview(player.view)

    }
    
    
    private func playVideo (url: NSURL) {
        
        player.contentURL = url
        player.prepareToPlay()
    }
}



extension ViewController: CTAssetsPickerControllerDelegate {

    func assetsPickerController(picker: CTAssetsPickerController!, didFinishPickingAssets assets: [AnyObject]!) {
        
        self.alAssetsPicked = assets
        picker.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.generateSequenceAlbum()
        })
    }
}



//MARK: Album Create
extension ViewController {
    
    func generateSequenceAlbum () {
        
        if  let alAssets = self.alAssetsPicked {
            let videoURL = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("BaseVideo", ofType: "m4v")!)
            //let audioURL = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("music", ofType: "mp3")!)
            
            let renderLayerSize = WSDynamicAlbumMaker.sharedInstance.querySizeWithAssetURL(videoURL: videoURL!)
            
            MBProgressHUD.showHUDAddedTo(self.view, animated: true)

            let albumLayer = self.createSequenceAlbumCALayer(renderLayerSize, assets: alAssets)
            
            let duration = Float(alAssets.count * 4 + 4)
            
            WSDynamicAlbumMaker.sharedInstance.createDynamicAlbum(videoURL: videoURL!, renderLayer: albumLayer, duration: duration, completionBlock: { (url, error) -> Void in
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                println("export done")
                if let err = error {
                    println("export error")
                } else {
                    self.playVideo(url!)
                }
                
                return
            })
        }
    }
    
    
    private func createSequenceAlbumCALayer (size: CGSize, assets: [AnyObject]!) -> CALayer {
        
        
        let canvasLayer = CALayer()
        canvasLayer.frame = CGRectMake(0, 0, size.width, size.height)
        canvasLayer.backgroundColor = UIColor.blackColor().CGColor
        
        for index in 0..<assets.count {
            
            let alAsset = assets[index] as! ALAsset
            
            let representation = alAsset.defaultRepresentation()
            let cgimage = representation.fullScreenImage().takeUnretainedValue()
            
            let photoLayer = CALayer()
            photoLayer.frame = CGRectMake(0, 0, size.width, size.height)
            photoLayer.contents = cgimage
            photoLayer.contentsGravity = kCAGravityResizeAspectFill
            photoLayer.backgroundColor = UIColor.whiteColor().CGColor
            photoLayer.opacity = 0
            
            
            let animatePhotoLayer = CABasicAnimation(keyPath: "opacity")
            animatePhotoLayer.fromValue = 0
            animatePhotoLayer.toValue = 1
            animatePhotoLayer.duration = 2
            animatePhotoLayer.fillMode = kCAFillModeForwards
            animatePhotoLayer.removedOnCompletion = false
            
            let skipBeginTime = CFTimeInterval(4 * index + 2)
            
            animatePhotoLayer.beginTime = WSDynamicAlbumMaker.sharedInstance.getCoreAnimationBeginTimeAtZero() + skipBeginTime
            photoLayer.addAnimation(animatePhotoLayer, forKey: "opacityChange")
            
            
            canvasLayer.addSublayer(photoLayer)
            
        }
        
        return canvasLayer
    }
}

