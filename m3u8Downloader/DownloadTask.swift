//
//  DownloadTask.swift
//  m3u8Downloader
//
//  Created by fandong on 2025/11/23.
//

import Foundation
internal import Combine

enum DownloadStatus: String, Codable {
    case waiting = "等待中"
    case downloading = "下载中"
    case paused = "已暂停"
    case merging = "合并中"
    case converting = "转换中"
    case completed = "已完成"
    case failed = "失败"
}

class DownloadTask: Identifiable, ObservableObject {
    let id: UUID
    @Published var fileName: String
    @Published var m3u8URL: String
    @Published var status: DownloadStatus
    @Published var progress: Double
    @Published var currentSegment: Int
    @Published var totalSegments: Int
    @Published var outputURL: URL?
    @Published var errorMessage: String?
    
    var isPaused: Bool = false
    var downloadedSegments: Set<Int> = []
    var segmentURLs: [URL] = []
    
    init(fileName: String, m3u8URL: String) {
        self.id = UUID()
        self.fileName = fileName
        self.m3u8URL = m3u8URL
        self.status = .waiting
        self.progress = 0.0
        self.currentSegment = 0
        self.totalSegments = 0
        self.outputURL = nil
        self.errorMessage = nil
    }
    
    var statusIcon: String {
        switch status {
        case .waiting:
            return "clock"
        case .downloading:
            return "arrow.down.circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .merging, .converting:
            return "gearshape.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    var canPause: Bool {
        status == .downloading
    }
    
    var canResume: Bool {
        status == .paused
    }
    
    var canShare: Bool {
        status == .completed && outputURL != nil
    }
}
