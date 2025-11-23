//
//  M3U8Parser.swift
//  m3u8Downloader
//
//  Created by fandong on 2025/11/23.
//

import Foundation

class M3U8Parser {
    
    static func parse(m3u8URL: String) async throws -> [URL] {
        guard let url = URL(string: m3u8URL) else {
            throw M3U8Error.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw M3U8Error.invalidContent
        }
        
        return try parseContent(content, baseURL: url)
    }
    
    private static func parseContent(_ content: String, baseURL: URL) throws -> [URL] {
        var segmentURLs: [URL] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // 跳过注释和空行
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            // 处理分片 URL
            if let segmentURL = resolveURL(trimmed, baseURL: baseURL) {
                segmentURLs.append(segmentURL)
            }
        }
        
        if segmentURLs.isEmpty {
            throw M3U8Error.noSegmentsFound
        }
        
        return segmentURLs
    }
    
    private static func resolveURL(_ urlString: String, baseURL: URL) -> URL? {
        // 如果是绝对 URL
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return URL(string: urlString)
        }
        
        // 如果是相对 URL
        if urlString.hasPrefix("/") {
            // 相对于域名根目录
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            components?.path = urlString
            return components?.url
        } else {
            // 相对于当前目录
            return URL(string: urlString, relativeTo: baseURL.deletingLastPathComponent())
        }
    }
}

enum M3U8Error: LocalizedError {
    case invalidURL
    case invalidContent
    case noSegmentsFound
    case downloadFailed(String)
    case mergeFailed
    case conversionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 M3U8 链接"
        case .invalidContent:
            return "无法解析 M3U8 内容"
        case .noSegmentsFound:
            return "未找到视频分片"
        case .downloadFailed(let message):
            return "下载失败: \(message)"
        case .mergeFailed:
            return "合并分片失败"
        case .conversionFailed:
            return "转换 MP4 失败"
        }
    }
}
