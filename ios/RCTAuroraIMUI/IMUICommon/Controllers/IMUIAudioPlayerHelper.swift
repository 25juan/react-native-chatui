//
//  IMUIAudioPlayerHelper.swift
//  IMUIChat
//
//  Created by oshumini on 2017/3/9.
//  Copyright © 2017年 HXHG. All rights reserved.
//

import UIKit
import AVFoundation

public protocol IMUIAudioPlayerDelegate:NSObjectProtocol {
  func didAudioPlayerBeginPlay(_ AudioPlayer:AVAudioPlayer)
  func didAudioPlayerStopPlay(_ AudioPlayer:AVAudioPlayer)
  func didAudioPlayerPausePlay(_ AudioPlayer:AVAudioPlayer)
}

public class IMUIAudioPlayerHelper: NSObject {
  
  static let sharedInstance = IMUIAudioPlayerHelper()
  

  var player:AVAudioPlayer!
  weak var delegate:IMUIAudioPlayerDelegate?

  // play tick callback
  public typealias ProgressCallback = (_ currentTime: TimeInterval, _ duration: TimeInterval) -> ()
  public typealias FinishCallback = () -> ()
  
  var playProgressCallback: ProgressCallback?
  var playFinishCallback: FinishCallback?
  var updater: CADisplayLink! = nil
  
  override init() {
    super.init()
    NotificationCenter.default.addObserver(self, selector: #selector(sensorStateChange(notification:)), name: NSNotification.Name(rawValue: "UIDeviceProximityStateDidChangeNotification"), object: nil)
    
  }
  
    func  sensorStateChange(notification:Notification) {
        if UIDevice.current.proximityState {
            do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
                
            }catch let error as NSError {
                print("set category fail \(error)")
            }
        }else{
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                
            }catch let error as NSError {
                print("set category fail \(error)")
            }
        }
    }
    
  open func playAudioWithData(_ voiceData:Data, progressCallback: @escaping ProgressCallback, finishCallBack: @escaping FinishCallback) {
    do {
      self.playProgressCallback = progressCallback
      self.playFinishCallback = finishCallBack
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
      updater = CADisplayLink(target: self, selector: #selector(self.trackAudio))
      updater.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
      updater.frameInterval = 1
    } catch let error as NSError {
      print("set category fail \(error)")
    }
    
    if self.player != nil {
      self.player.stop()
      self.player = nil
    }
    do {
      let voicePlayer:AVAudioPlayer = try AVAudioPlayer(data: voiceData)
      voicePlayer.delegate = self
      voicePlayer.play()
      self.player = voicePlayer
    } catch let error as NSError {
      print("alloc AVAudioPlayer with voice data fail with error \(error)")
    }
    
    UIDevice.current.isProximityMonitoringEnabled = true
  }
  
  func trackAudio() {
    self.playProgressCallback?(player.currentTime, player.duration)
  }
  
  func pausePlayingAudio() {
    self.player?.pause()
    updater.invalidate()
    
  }
  
  func resumePlayingAudio() {
    self.player?.play()
    updater.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
  }
  
  func stopAudio() {
    if self.player != nil{
        if self.player.isPlaying {
            self.player.stop()
        }
        updater.invalidate()
        UIDevice.current.isProximityMonitoringEnabled = false
        self.delegate?.didAudioPlayerStopPlay(self.player)
    }
  }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


// MARK: - AVAudioPlayerDelegate
extension IMUIAudioPlayerHelper: AVAudioPlayerDelegate {
  public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    self.stopAudio()
    self.playFinishCallback?()
  }
}
