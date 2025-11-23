//
//  M3U8DownloadManager.swift
//  m3u8Downloader
//
//  Created by fandong on 2025/11/23.
//

import Foundation
import AVFoundation
internal import Combine

@MainActor
class M3U8DownloadManager: ObservableObject {
    @Published var tasks: [DownloadTask] = []
    
    private let fileManager = FileManager.default
    private var downloadTasks: [UUID: Task<Void, Never>] = [:]
    
    // 获取文档目录
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // 添加新任务
    func addTask(fileName: String, m3u8URL: String) {
        let task = DownloadTask(fileName: fileName, m3u8URL: m3u8URL)
        tasks.append(task)
        
        // 自动开始下载
        Task {
            await startDownload(task: task)
        }
    }
    
    // 开始下载
    func startDownload(task: DownloadTask) async {
        guard task.status == .waiting || task.status == .paused else { return }
        
        task.status = .downloading
        task.isPaused = false
        
        let downloadTask = Task {
            do {
                // 1. 解析 M3U8
                if task.segmentURLs.isEmpty {
                    let segments = try await M3U8Parser.parse(m3u8URL: task.m3u8URL)
                    task.segmentURLs = segments
                    task.totalSegments = segments.count
                }
                
                // 2. 下载分片
                try await downloadSegments(task: task)
                
                if task.isPaused { return }
                
                // 3. 合并分片
                task.status = .merging
                let tsURL = try await mergeSegments(task: task)
                
                if task.isPaused { return }
                
                // 4. 转换为 MP4
                task.status = .converting
                try await convertToMP4(task: task, tsURL: tsURL)
                
                // 5. 清理临时文件
                cleanupTemporaryFiles(task: task)
                
                task.status = .completed
                task.progress = 1.0
                
            } catch {
                if !task.isPaused {
                    task.status = .failed
                    task.errorMessage = error.localizedDescription
                }
            }
        }
        
        downloadTasks[task.id] = downloadTask
    }
    
    // 下载所有分片
    private func downloadSegments(task: DownloadTask) async throws {
        let tempDir = documentsDirectory.appendingPathComponent("temp_\(task.id.uuidString)")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        for (index, segmentURL) in task.segmentURLs.enumerated() {
            if task.isPaused { return }
            
            // 跳过已下载的分片
            if task.downloadedSegments.contains(index) {
                continue
            }
            
            let segmentPath = tempDir.appendingPathComponent("segment_\(index).ts")
            
            do {
                let (data, _) = try await URLSession.shared.data(from: segmentURL)
                try data.write(to: segmentPath)
                
                task.downloadedSegments.insert(index)
                task.currentSegment = index + 1
                task.progress = Double(task.currentSegment) / Double(task.totalSegments) * 0.7 // 下载占70%进度
            } catch {
                throw M3U8Error.downloadFailed("分片 \(index) 下载失败")
            }
        }
    }
    
    // 合并分片
    private func mergeSegments(task: DownloadTask) async throws -> URL {
        let tempDir = documentsDirectory.appendingPathComponent("temp_\(task.id.uuidString)")
        let outputTSURL = documentsDirectory.appendingPathComponent("\(task.fileName).ts")
        
        // 删除旧文件
        try? fileManager.removeItem(at: outputTSURL)
        
        // 创建输出文件
        fileManager.createFile(atPath: outputTSURL.path, contents: nil)
        guard let fileHandle = FileHandle(forWritingAtPath: outputTSURL.path) else {
            throw M3U8Error.mergeFailed
        }
        
        defer {
            try? fileHandle.close()
        }
        
        // 按顺序合并所有分片
        for index in 0..<task.totalSegments {
            if task.isPaused { throw M3U8Error.mergeFailed }
            
            let segmentPath = tempDir.appendingPathComponent("segment_\(index).ts")
            
            if let data = try? Data(contentsOf: segmentPath) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
            }
            
            // 更新进度 (70%-85%)
            task.progress = 0.7 + Double(index + 1) / Double(task.totalSegments) * 0.15
        }
        
        return outputTSURL
    }
    
    // 转换为 MP4
    private func convertToMP4(task: DownloadTask, tsURL: URL) async throws {
        let outputMP4URL = documentsDirectory.appendingPathComponent("\(task.fileName).mp4")
        
        // 删除旧文件
        try? fileManager.removeItem(at: outputMP4URL)
        
        let asset = AVURLAsset(url: tsURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw M3U8Error.conversionFailed
        }
        
        exportSession.outputURL = outputMP4URL
        exportSession.outputFileType = .mp4
        
        await exportSession.export()
        
        guard exportSession.status == .completed else {
            throw M3U8Error.conversionFailed
        }
        
        task.outputURL = outputMP4URL
        task.progress = 1.0
    }
    
    // 清理临时文件
    private func cleanupTemporaryFiles(task: DownloadTask) {
        let tempDir = documentsDirectory.appendingPathComponent("temp_\(task.id.uuidString)")
        try? fileManager.removeItem(at: tempDir)
        
        // 删除 TS 文件
        let tsURL = documentsDirectory.appendingPathComponent("\(task.fileName).ts")
        try? fileManager.removeItem(at: tsURL)
    }
    
    // 暂停下载
    func pauseDownload(task: DownloadTask) {
        guard task.canPause else { return }
        
        task.isPaused = true
        task.status = .paused
        
        downloadTasks[task.id]?.cancel()
        downloadTasks.removeValue(forKey: task.id)
    }
    
    // 继续下载
    func resumeDownload(task: DownloadTask) {
        guard task.canResume else { return }
        
        Task {
            await startDownload(task: task)
        }
    }
    
    // 删除任务
    func deleteTask(task: DownloadTask) {
        pauseDownload(task: task)
        cleanupTemporaryFiles(task: task)
        
        if let outputURL = task.outputURL {
            try? fileManager.removeItem(at: outputURL)
        }
        
        tasks.removeAll { $0.id == task.id }
    }
    
    // 获取分享 URL
    func getShareURL(task: DownloadTask) -> URL? {
        return task.outputURL
    }
}
