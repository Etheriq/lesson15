//
//  ViewController.swift
//  swift1
//
//  Created by Yuriy T on 06.03.16.
//  Copyright © 2016 Yuriy T. All rights reserved.
//

import UIKit
import Foundation
import MWPhotoBrowser

class ViewController: UIViewController, NSURLSessionDataDelegate, UITableViewDataSource, UITableViewDelegate, MWPhotoBrowserDelegate {

    @IBOutlet weak var table: UITableView!
    var session: NSURLSession!
    var gallerySession: NSURLSession!
    var galleryPhotos = []
    var galleryItems = []
    var itunesEntries = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationItem.title = "Track list";
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPMaximumConnectionsPerHost = 3
        
        session = NSURLSession.init(configuration: configuration, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        
        session.dataTaskWithURL(NSURL.init(string: "https://itunes.apple.com/search?term=rock&country=US&entity=song")!, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            do {
                if let _ = NSString(data:data!, encoding: NSUTF8StringEncoding) {
                    let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    self.itunesEntries = jsonDictionary["results"] as! NSArray
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    self.table.reloadData()
                }
            } catch _ as NSError {}
        }).resume()
    
        
        let fileManager = NSFileManager.defaultManager()
        let path = NSHomeDirectory().stringByAppendingString("Library").stringByAppendingString("Application Support")
        
        if !fileManager.fileExistsAtPath(path) {
            
            do {
                try fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
            } catch _ as NSError {}
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let indexPath = self.table.indexPathForSelectedRow
        
        if indexPath != nil {
            self.table.deselectRowAtIndexPath(indexPath!, animated: true)
        }
    }

    //MARK - UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return self.itunesEntries.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identificator = "cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(identificator, forIndexPath: indexPath) as! iTuneCell
        cell.configureCellWithiTuneObject(self.itunesEntries.objectAtIndex(indexPath.row) as! [String : String])
        if !cell.isDownloaded! {
            cell.playButton.enabled = false
            cell.downloadButton.enabled = true
            cell.downloadProgressBar.setProgress(0, animated: true)
            cell.downloadStatusLabel.text = "0 of 0"
        } else {
            cell.playButton.enabled = true
            cell.downloadButton.enabled = false
            cell.downloadProgressBar.setProgress(1, animated: true)
            cell.downloadStatusLabel.text = "Downloaded"
        }
            
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.session.dataTaskWithURL(NSURL.init(string: cell.imageUrl!)!, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                cell.imageView!.image = UIImage.init(data: data!)
             })
        }
         
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let iTuneItem = self.itunesEntries.objectAtIndex(indexPath.row) as! [String : String]
        
        self.galleryPhotos = []
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPMaximumConnectionsPerHost = 3
        configuration.allowsCellularAccess = false
        configuration.HTTPAdditionalHeaders = ["Authorization": "Client-ID 510d3df1e146294"]
        
        session = NSURLSession.init(configuration: configuration, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        
        let rawPath = "https://api.imgur.com/3/gallery/search/top/0?q=" + iTuneItem["artistName"]!
        let imgurUrl = rawPath.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        
        session.dataTaskWithURL(NSURL.init(string: imgurUrl!)!, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            do {
                if let _ = NSString(data:data!, encoding: NSUTF8StringEncoding) {
                    let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    self.galleryItems = jsonDictionary["data"] as! NSArray
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    self.showGallery()
                }
            } catch _ as NSError {}
        }).resume()
    }

    func showGallery() {
        
        for item : Dictionary  in self.galleryItems {
            let photo : MWPhoto = MWPhoto.init(URL: NSURL.init(string: item["link"]))

            if let title = item["title"] {
                
            } else {
                title = ""
            }
            if let descr = item["description"] {
                
            } else {
                descr = ""
            }
            photo.caption = "\(title) \(descr)"
            self.galleryPhotos.append(photo)
        }
        
        let browser : MWPhotoBrowser = MWPhotoBrowser.init(delegate: self)
        
        browser.displayActionButton = false // Show action button to allow sharing, copying, etc (defaults to YES)
        browser.displayNavArrows = true // Whether to display left and right nav arrows on toolbar (defaults to NO)
        browser.displaySelectionButtons = false // Whether selection buttons are shown on each image (defaults to NO)
        browser.zoomPhotosToFill = true // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
        browser.alwaysShowControls = false // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
        browser.enableGrid = true // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
        browser.startOnGrid = true // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
        browser.autoPlayOnAppear = false // Auto-play first video
        
        browser.setCurrentPhotoIndex(1)
        
        self.navigationController?.pushViewController(browser, animated: true)
    }
    
    func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser!) -> UInt {
        return self.galleryPhotos.count
    }

    func photoBrowser(photoBrowser: MWPhotoBrowser!, photoAtIndex index: UInt) -> MWPhotoProtocol! {
        if index <= self.galleryPhotos.count {
            return self.galleryPhotos.objectAtIndex(index)
        }
        
        return nil;
    }

}

