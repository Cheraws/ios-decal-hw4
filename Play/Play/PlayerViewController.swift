//
//  PlayerViewController.swift
//  Play
//
//  Created by Gene Yoo on 11/26/15.
//  Copyright © 2015 cs198-1. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class PlayerViewController: UIViewController {
    var tracks: [Track]!
    var scAPI: SoundCloudAPI!
    var isFirst: Bool = true
    var currentIndex: Int!
    var player: AVQueuePlayer!
    var trackImageView: UIImageView!

    var playPauseButton: UIButton!
    var nextButton: UIButton!
    var previousButton: UIButton!

    var artistLabel: UILabel!
    var titleLabel: UILabel!
    var didPlay: [Track]!

    var paused = true

    override func viewDidLoad() {
        super.viewDidLoad()
        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.white

        scAPI = SoundCloudAPI()
        scAPI.loadTracks(didLoadTracks)
        self.didPlay = []
        currentIndex = 0

        player = AVQueuePlayer()

        loadVisualElements()
        loadPlayerButtons()
    }

    func loadVisualElements() {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let offset = height - width


        trackImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0,
                                                   width: width, height: width))
        trackImageView.contentMode = UIViewContentMode.scaleAspectFill
        trackImageView.clipsToBounds = true
        view.addSubview(trackImageView)

        titleLabel = UILabel(frame: CGRect(x: 0.0, y: width + offset * 0.15,
                                           width: width, height: 20.0))
        titleLabel.textAlignment = NSTextAlignment.center
        view.addSubview(titleLabel)

        artistLabel = UILabel(frame: CGRect(x: 0.0, y: width + offset * 0.25,
                                            width: width, height: 20.0))
        artistLabel.textAlignment = NSTextAlignment.center
        artistLabel.textColor = UIColor.gray
        view.addSubview(artistLabel)
    }


    func loadPlayerButtons() {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let offset = height - width

        let playImage = UIImage(named: "play")?.withRenderingMode(.alwaysTemplate)
        let pauseImage = UIImage(named: "pause")?.withRenderingMode(.alwaysTemplate)
        let nextImage = UIImage(named: "next")?.withRenderingMode(.alwaysTemplate)
        let previousImage = UIImage(named: "previous")?.withRenderingMode(.alwaysTemplate)

        playPauseButton = UIButton(type: UIButtonType.custom)
        playPauseButton.frame = CGRect(x: width / 2.0 - width / 30.0,
                                       y: width + offset * 0.5,
                                       width: width / 15.0,
                                       height: width / 15.0)
        playPauseButton.setImage(playImage, for: UIControlState())
        playPauseButton.setImage(pauseImage, for: UIControlState.selected)
        playPauseButton.addTarget(self, action: #selector(playOrPauseTrack),
                                  for: .touchUpInside)
        view.addSubview(playPauseButton)

        previousButton = UIButton(type: UIButtonType.custom)
        previousButton.frame = CGRect(x: width / 2.0 - width / 30.0 - width / 5.0,
                                      y: width + offset * 0.5,
                                      width: width / 15.0,
                                      height: width / 15.0)
        previousButton.setImage(previousImage, for: UIControlState())
        previousButton.addTarget(self, action: #selector(previousTrackTapped(_:)),
                                 for: UIControlEvents.touchUpInside)
        view.addSubview(previousButton)

        nextButton = UIButton(type: UIButtonType.custom)
        nextButton.frame = CGRect(x: width / 2.0 - width / 30.0 + width / 5.0,
                                  y: width + offset * 0.5,
                                  width: width / 15.0,
                                  height: width / 15.0)
        nextButton.setImage(nextImage, for: UIControlState())
        nextButton.addTarget(self, action: #selector(nextTrackTapped(_:)),
                             for: UIControlEvents.touchUpInside)
        view.addSubview(nextButton)

    }

    func loadTrackElements() {
        let track = tracks[currentIndex]
        asyncLoadTrackImage(track)
        titleLabel.text = track.title
        artistLabel.text = track.artist
    }

    /*
     *  This Method should play or pause the song, depending on the song's state
     *  It should also toggle between the play and pause images by toggling
     *  sender.selected
     *
     *  If you are playing the song for the first time, you should be creating
     *  an AVPlayerItem from a url and updating the player's currentitem
     *  property accordingly.
     */
    
    func playOrPauseTrack(_ sender: UIButton) {
        let path = Bundle.main.path(forResource: "Info", ofType: "plist")
        let clientID = NSDictionary(contentsOfFile: path!)?.value(forKey: "client_id") as! String
        let track = tracks[currentIndex]
        let url = URL(string: "https://api.soundcloud.com/tracks/\(track.id as Int)/stream?client_id=\(clientID)")!
        if (isFirst){
            let song = AVPlayerItem(url: url)
            self.player = AVQueuePlayer(playerItem: song)
            
            print (String(describing: player.currentItem!.status))
            isFirst = false
        }
        if sender.isSelected{
            self.player.pause()
            sender.setImage(UIImage(named: "play.png"), for: UIControlState.normal)
        }
        else{
            self.player.play()
            print (player.currentItem!.status)
        }
        print("Am i in here?")
        sender.isSelected = !sender.isSelected
    }

    /*
     * Called when the next button is tapped. It should check if there is a next
     * track, and if so it will load the next track's data and
     * automatically play the song if a song is already playing
     * Remember to update the currentIndex
     */
    func nextTrackTapped(_ sender: UIButton) {
        let rate = self.player.rate
        if (currentIndex + 1 <= tracks.count){
            
            currentIndex = currentIndex + 1
            let path = Bundle.main.path(forResource: "Info", ofType: "plist")
            let clientID = NSDictionary(contentsOfFile: path!)?.value(forKey: "client_id") as! String
            let track = tracks[currentIndex]
            let url = URL(string: "https://api.soundcloud.com/tracks/\(track.id as Int)/stream?client_id=\(clientID)")!
            let song = AVPlayerItem(url: url)
            self.player = AVQueuePlayer(playerItem: song)
            if (rate != 0){
                self.player.play()
            }
            else{
                print("nothing happens?")
            }
            
        }
        loadTrackElements()
    }

    /*
     * Called when the previous button is tapped. It should behave in 2 possible
     * ways:
     *    a) If a song is more than 3 seconds in, seek to the beginning (time 0)
     *    b) Otherwise, check if there is a previous track, and if so it will
     *       load the previous track's data and automatically play the song if
     *      a song is already playing
     *  Remember to update the currentIndex if necessary
     */

    func previousTrackTapped(_ sender: UIButton) {
        let rate = self.player.rate
        let t1 = Float(self.player.currentTime().value)
        let t2 = Float(self.player.currentTime().timescale)
        let current = t1 / t2
        if (current > 3){
            self.player.seek(to: kCMTimeZero)
            
        }
        else{
            if (currentIndex - 1 <= tracks.count && currentIndex - 1 >= 0){
                currentIndex = currentIndex - 1
                let path = Bundle.main.path(forResource: "Info", ofType: "plist")
                let clientID = NSDictionary(contentsOfFile: path!)?.value(forKey: "client_id") as! String
                let track = tracks[currentIndex]
                let url = URL(string: "https://api.soundcloud.com/tracks/\(track.id as Int)/stream?client_id=\(clientID)")!
                let song = AVPlayerItem(url: url)
                self.player = AVQueuePlayer(playerItem: song)
                if (rate != 0){
                    self.player.play()
                }
                
            }
            loadTrackElements()
        }
    }


    func asyncLoadTrackImage(_ track: Track) {
        let url = URL(string: track.artworkURL)
        let session = URLSession(configuration: URLSessionConfiguration.default)

        let task = session.dataTask(with: url!) {(data, response, error) -> Void in
            if error == nil {
                let image = UIImage(data: data!)
                DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                    DispatchQueue.main.async {
                        self.trackImageView.image = image
                    }
                }
            }
        }
        task.resume()
    }
    
    func didLoadTracks(_ tracks: [Track]) {
        self.tracks = tracks
        loadTrackElements()
    }
}

