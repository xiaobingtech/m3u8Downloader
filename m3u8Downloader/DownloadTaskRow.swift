//
//  DownloadTaskRow.swift
//  m3u8Downloader
//
//  Created by fandong on 2025/11/23.
//

import SwiftUI

struct DownloadTaskRow: View {
    @ObservedObject var task: DownloadTask
    
    var onPause: () -> Void
    var onResume: () -> Void
    var onShare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 文件名和状态
            HStack {
                Image(systemName: task.statusIcon)
                    .foregroundColor(statusColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.fileName)
                        .font(.headline)
                    
                    Text(task.status.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let error = task.errorMessage {
                        Text(error)
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                // 操作按钮
                HStack(spacing: 12) {
                    if task.canPause {
                        Button(action: onPause) {
                            Image(systemName: "pause.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if task.canResume {
                        Button(action: onResume) {
                            Image(systemName: "play.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if task.canShare {
                        Button(action: onShare) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            // 进度条
            if task.status != .completed && task.status != .failed {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: task.progress)
                        .progressViewStyle(.linear)
                    
                    HStack {
                        if task.totalSegments > 0 {
                            Text("\(task.currentSegment) / \(task.totalSegments) 分片")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(task.progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusColor: Color {
        switch task.status {
        case .waiting:
            return .gray
        case .downloading:
            return .blue
        case .paused:
            return .orange
        case .merging, .converting:
            return .purple
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}
