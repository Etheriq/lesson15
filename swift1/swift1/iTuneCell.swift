//
//  iTuneCell.swift
//  swift1
//
//  Created by Yuriy T on 06.03.16.
//  Copyright © 2016 Yuriy T. All rights reserved.
//

import UIKit
import Foundation

class iTuneCell: UITableViewCell, NSURLSessionDelegate, NSURLSessionDownloadDelegate, AVAudioPlayerDelegate {

    var artistName : String?
    var trackName : String?
    var previewUrl : String?
    var albomName : String?
    var isDownloaded : Bool?
    var isPlay : Bool!
    var fileName : String?
    var imageUrl : String?
    var player : AVAudioPlayer?
    var timer : NSTimer?
    
    var session: NSURLSession!

    @IBOutlet weak var trackImage: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albomNameLabel: UILabel!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var downloadProgressBar: UIProgressView!
    @IBOutlet weak var downloadStatusLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCellWithiTuneObject(object: [String : String]) {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPMaximumConnectionsPerHost = 3
        
        session = NSURLSession.init(configuration: configuration, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        isPlay = false
        artistNameLabel.text = object["artistName"]!
        trackNameLabel.text = object["trackName"]!
        previewUrl = object["previewUrl"]!
        albomNameLabel.text = object["collectionName"]!
        imageUrl = object["artworkUrl100"]!
        
        let tmpurl = NSURL(string: previewUrl!)
        isDownloaded = self.checkOnDownloadedTrack(tmpurl!.lastPathComponent!)
        fileName = tmpurl!.lastPathComponent!
    }
    
    func checkOnDownloadedTrack(trackName : String) -> Bool {
        let trackPath = NSHomeDirectory().stringByAppendingString("Library").stringByAppendingString("Application Support").stringByAppendingString(trackName)
        if NSFileManager.defaultManager().fileExistsAtPath(trackPath) {
            return true
        }
        
        return false
    }
    
    func initPlayer() {
        if self.isDownloaded! {
            let trackPath = NSHomeDirectory().stringByAppendingString("Library").stringByAppendingString("Application Support").stringByAppendingString(self.fileName!)
            
            do {
                try self.player! = AVAudioPlayer.init(contentsOfURL: NSURL.init(string: trackPath)!)
                self.player!.delegate = self
            } catch _ as NSError {}
        }
    }
    
    @IBAction func playAction(sender: UIButton) {
        if let player = self.player {
           self.isPlay = !self.isPlay
            if self.isPlay! {
                self.playButton.setTitle("Pause", forState: UIControlState.Normal)
                player.play()
                self.timer! = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updateElapsedTime", userInfo: nil, repeats: true)
            } else {
                self.playButton.setTitle("Play", forState: UIControlState.Normal)
                player.pause()
                self.timer!.invalidate()
                self.timer = nil
            }
        } else {
            self.initPlayer()
        }
    }

    @IBAction func downloadAction(sender: UIButton) {
    
        let task = self.session.downloadTaskWithURL(NSURL.init(string: self.previewUrl!)!)
        task.resume()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func updateElapsedTime() {
        if let player = self.player {
            
            self.downloadProgressBar.setProgress((Float)(player.currentTime / player.duration), animated: true)
            self.downloadStatusLabel.text = self.formatTime(player.currentTime)
        }
    }
    
    func formatTime(time: Double) -> String {
        let minutes = time / 60
        let seconds = time % 60
        
        let str = NSString.init(format: "@%d:%@%d", (Bool)(minutes / 10) ? NSString.init(format: "%d", minutes / 10) : "", minutes % 10, NSString.init(format: "%d", seconds / 10), seconds % 10)
        
        return str as String
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        let fileManager = NSFileManager.defaultManager()
        var destinationUrl = NSHomeDirectory().stringByAppendingString("Library").stringByAppendingString("Application Support")
        
        let tmpurl = NSURL(string: self.previewUrl!)
        destinationUrl = destinationUrl.stringByAppendingString(tmpurl!.lastPathComponent!)
        
        if !fileManager.fileExistsAtPath(destinationUrl) {
            
            do {
                try fileManager.moveItemAtURL(location, toURL: NSURL.init(string: destinationUrl)!)
            } catch _ as NSError {}
        } else {
            
            do {
                try fileManager.createDirectoryAtPath(NSHomeDirectory().stringByAppendingString("Library").stringByAppendingString("Application Support"), withIntermediateDirectories: false, attributes: nil)
                do {
                    try fileManager.moveItemAtURL(location, toURL: NSURL.init(string: destinationUrl)!)
                } catch _ as NSError {}
            } catch _ as NSError{}
          
        }
        
        self.isDownloaded = true
        self.playButton.enabled = true
        self.downloadButton.enabled = false
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        self.initPlayer()
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let formatter = NSByteCountFormatter.init()
        
        self.downloadProgressBar.setProgress((Float)(totalBytesWritten / totalBytesExpectedToWrite), animated: true)
        self.downloadStatusLabel.text = NSString.init(format: "%@ of %@", formatter.stringFromByteCount(totalBytesWritten), formatter.stringFromByteCount(totalBytesExpectedToWrite)) as String
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        self.isPlay = false;
        self.playButton.setTitle("Play", forState: UIControlState.Normal)
        self.timer!.invalidate()
        self.timer = nil
    }
}
