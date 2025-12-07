//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitor
//
//  Created by Jan Podmolík on 07.12.2025.
//

import DeviceActivity
import FamilyControls
import Foundation
import os.log

/// Background extension that monitors device activity and updates progress.
/// Runs in a separate process - use os.log for debugging visibility.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    private let logger = Logger(
        subsystem: LogCategories.extensionSubsystem,
        category: "Monitor"
    )
    
    // MARK: - Debug Logging
    
    #if DEBUG
    /// Writes debug messages to a file in the shared container for debugging.
    /// Only available in DEBUG builds.
    private func writeDebugLog(_ message: String) {
        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        ) else {
            logger.error("Cannot get container URL for debug logging")
            return
        }
        
        let logFileURL = containerURL.appendingPathComponent("extension_log.txt")
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] \(message)\n"
        
        do {
            if fileManager.fileExists(atPath: logFileURL.path) {
                let handle = try FileHandle(forWritingTo: logFileURL)
                handle.seekToEndOfFile()
                if let data = logEntry.data(using: .utf8) {
                    handle.write(data)
                }
                handle.closeFile()
            } else {
                try logEntry.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            logger.error("Failed to write debug log: \(error.localizedDescription)")
        }
        
        // Also log via os.log for Console.app visibility
        logger.info("\(message)")
    }
    #else
    private func writeDebugLog(_ message: String) {
        // In release builds, only log essential info via os.log
        logger.info("\(message)")
    }
    #endif
    
    // MARK: - DeviceActivityMonitor Overrides
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        writeDebugLog("Interval started for activity: \(activity.rawValue)")
        
        #if DEBUG
        // Log selection details for debugging
        if let selection = SharedDefaults.selection {
            writeDebugLog("Selection: \(selection.applicationTokens.count) apps, \(selection.categoryTokens.count) categories")
        } else {
            writeDebugLog("Warning: Cannot read selection from SharedDefaults")
        }
        writeDebugLog("Daily limit: \(SharedDefaults.dailyLimitMinutes) minutes")
        #endif
        
        // Reset progress at the start of the monitoring interval
        SharedDefaults.currentProgress = 0
        SharedDefaults.lastMonitorUpdate = Date()
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        writeDebugLog("Interval ended for activity: \(activity.rawValue)")
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        writeDebugLog("Threshold reached: \(event.rawValue)")
        
        // Parse threshold percentage from event name "threshold_X"
        guard let thresholdValue = parseThresholdValue(from: event.rawValue) else {
            logger.warning("Could not parse threshold from event: \(event.rawValue)")
            return
        }
        
        SharedDefaults.currentProgress = thresholdValue
        SharedDefaults.lastMonitorUpdate = Date()
        
        writeDebugLog("Progress updated to \(thresholdValue)%")
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        writeDebugLog("Interval will start warning for: \(activity.rawValue)")
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        writeDebugLog("Interval will end warning for: \(activity.rawValue)")
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        writeDebugLog("Threshold warning for: \(event.rawValue)")
    }
    
    // MARK: - Helpers
    
    /// Parses threshold percentage from event name format "threshold_X"
    private func parseThresholdValue(from eventName: String) -> Int? {
        guard eventName.hasPrefix("threshold_"),
              let valueString = eventName.components(separatedBy: "_").last,
              let value = Int(valueString) else {
            return nil
        }
        return value
    }
}

