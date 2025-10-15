import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

class VideoAudioConverter {
    
    static func convertVideoToAudio(videoURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: videoURL)
        
        // アセットの基本情報を読み込み
        let keys = ["tracks", "duration"]
        asset.loadValuesAsynchronously(forKeys: keys) {
            var error: NSError?
            
            // トラックの読み込み確認
            let tracksStatus = asset.statusOfValue(forKey: "tracks", error: &error)
            if tracksStatus != .loaded {
                DispatchQueue.main.async {
                    completion(.failure(error ?? VideoConversionError.exportFailed))
                }
                return
            }
            
            // 音声トラックの確認
            let audioTracks = asset.tracks(withMediaType: .audio)
            guard !audioTracks.isEmpty else {
                DispatchQueue.main.async {
                    completion(.failure(VideoConversionError.noAudioTrack))
                }
                return
            }
            
            // 一時的なM4AファイルのURLを作成
            let tempDirectory = FileManager.default.temporaryDirectory
            let m4aFileName = UUID().uuidString + ".m4a"
            let m4aURL = tempDirectory.appendingPathComponent(m4aFileName)
            
            // エクスポートセッションを作成
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
                DispatchQueue.main.async {
                    completion(.failure(VideoConversionError.exportSessionCreationFailed))
                }
                return
            }
            
            // 出力設定
            exportSession.outputURL = m4aURL
            exportSession.outputFileType = .m4a
            exportSession.shouldOptimizeForNetworkUse = false
            
            // 音声トラックのみをエクスポート
            exportSession.audioMix = createAudioMix(for: asset)
            
            // エクスポート実行
            exportSession.exportAsynchronously {
                DispatchQueue.main.async {
                    switch exportSession.status {
                    case .completed:
                        // M4Aファイルをそのまま返す（WAV変換は不要）
                        completion(.success(m4aURL))
                    case .failed:
                        let error = exportSession.error ?? VideoConversionError.exportFailed
                        print("Export failed: \(error.localizedDescription)")
                        completion(.failure(error))
                    case .cancelled:
                        print("Export cancelled")
                        completion(.failure(VideoConversionError.exportCancelled))
                    default:
                        print("Export status: \(exportSession.status.rawValue)")
                        completion(.failure(VideoConversionError.unknownError))
                    }
                }
            }
        }
    }
    
    private static func createAudioMix(for asset: AVAsset) -> AVAudioMix? {
        let audioMix = AVMutableAudioMix()
        let audioMixParams = AVMutableAudioMixInputParameters()
        
        // 音声トラックを取得
        let audioTracks = asset.tracks(withMediaType: .audio)
        if let audioTrack = audioTracks.first {
            audioMixParams.trackID = audioTrack.trackID
            audioMix.inputParameters = [audioMixParams]
            return audioMix
        }
        
        return nil
    }
    
    
    static func isVideoFile(url: URL) -> Bool {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "3gp", "flv", "wmv", "webm"]
        let fileExtension = url.pathExtension.lowercased()
        return videoExtensions.contains(fileExtension)
    }
}

enum VideoConversionError: Error, LocalizedError {
    case exportSessionCreationFailed
    case exportFailed
    case exportCancelled
    case unknownError
    case noAudioTrack
    
    var errorDeCription: String? {
        switch self {
        case .exportSessionCreationFailed:
            return "Failed to create export session"
        case .exportFailed:
            return "Video to audio conversion failed"
        case .exportCancelled:
            return "Video to audio conversion was cancelled"
        case .unknownError:
            return "Unknown error occurred during conversion"
        case .noAudioTrack:
            return "No audio track found in video file"
        }
    }
}
