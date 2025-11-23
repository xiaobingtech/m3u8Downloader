//
//  ContentView.swift
//  m3u8Downloader
//
//  Created by fandong on 2025/11/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var downloadManager = M3U8DownloadManager()
    @State private var showingAddSheet = false
    @State private var shareItem: URL?
    
    var body: some View {
        NavigationView {
            ZStack {
                // 下载列表
                if downloadManager.tasks.isEmpty {
                    emptyState
                } else {
                    downloadList
                }
                
                // 圆形新增按钮
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("M3U8 下载器")
            .sheet(isPresented: $showingAddSheet) {
                AddDownloadSheet(isPresented: $showingAddSheet) { fileName, m3u8URL in
                    downloadManager.addTask(fileName: fileName, m3u8URL: m3u8URL)
                }
            }
            .sheet(item: $shareItem) { url in
                ShareSheet(url: url)
            }
        }
    }
    
    // 空状态视图
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("暂无下载任务")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("点击右下角按钮添加下载")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    // 下载列表视图
    private var downloadList: some View {
        List {
            ForEach(downloadManager.tasks) { task in
                DownloadTaskRow(
                    task: task,
                    onPause: {
                        downloadManager.pauseDownload(task: task)
                    },
                    onResume: {
                        downloadManager.resumeDownload(task: task)
                    },
                    onShare: {
                        if let url = downloadManager.getShareURL(task: task) {
                            shareItem = url
                        }
                    }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        downloadManager.deleteTask(task: task)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    // 新增按钮
    private var addButton: some View {
        Button(action: {
            showingAddSheet = true
        }) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.blue)
                        .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                )
        }
    }
}

// 分享视图
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// 为 URL 添加 Identifiable 支持
extension URL: Identifiable {
    public var id: String {
        absoluteString
    }
}

#Preview {
    ContentView()
}
