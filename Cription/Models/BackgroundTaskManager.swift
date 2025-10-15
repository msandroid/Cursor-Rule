//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
#if canImport(UIKit)
import UIKit
import BackgroundTasks
#endif

class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    #if canImport(UIKit)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    #endif
    #if canImport(UIKit)
    private let backgroundTaskIdentifier = "com.Cription.whisperax.background-processing"
    #endif
    
    private init() {
        #if canImport(UIKit)
        registerBackgroundTasks()
        #endif
    }
    
    #if canImport(UIKit)
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundTask(task: task as! BGProcessingTask)
        }
    }
    
    private func handleBackgroundTask(task: BGProcessingTask) {
        // Set expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform background work
        performBackgroundWork { success in
            task.setTaskCompleted(success: success)
        }
    }
    #endif
    
    private func performBackgroundWork(completion: @escaping (Bool) -> Void) {
        // Perform any necessary background processing
        // For WhisperAX, this could include:
        // - Processing queued audio files
        // - Updating model cache
        // - Syncing data
        
        DispatchQueue.global(qos: .background).async {
            // Simulate background work
            Thread.sleep(forTimeInterval: 1.0)
            
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    func startBackgroundTask() {
        #if canImport(UIKit)
        guard backgroundTaskID == .invalid else { return }
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "WhisperAXBackgroundTask") {
            self.endBackgroundTask()
        }
        #endif
    }
    
    func endBackgroundTask() {
        #if canImport(UIKit)
        guard backgroundTaskID != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
        #endif
    }
    
    func scheduleBackgroundProcessing() {
        #if canImport(UIKit)
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background processing: \(error)")
        }
        #endif
    }
    
    func checkBackgroundRefreshStatus() -> Any? {
        #if canImport(UIKit)
        return UIApplication.shared.backgroundRefreshStatus
        #else
        return nil
        #endif
    }
    
    func isBackgroundRefreshEnabled() -> Bool {
        #if canImport(UIKit)
        if let status = checkBackgroundRefreshStatus() as? UIBackgroundRefreshStatus {
            return status == .available
        }
        return false
        #else
        return false
        #endif
    }
}
