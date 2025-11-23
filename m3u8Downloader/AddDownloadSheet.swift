//
//  AddDownloadSheet.swift
//  m3u8Downloader
//
//  Created by fandong on 2025/11/23.
//

import SwiftUI

struct AddDownloadSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    
    @State private var m3u8URL: String = ""
    @State private var fileName: String = ""
    
    var onAdd: (String, String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("下载信息")) {
                    TextField("M3U8 链接", text: $m3u8URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    TextField("文件名（不含后缀）", text: $fileName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section {
                    HStack {
                        Spacer()
                        Button("取消") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("确定") {
                            if !m3u8URL.isEmpty && !fileName.isEmpty {
                                onAdd(fileName, m3u8URL)
                                dismiss()
                            }
                        }
                        .bold()
                        .disabled(m3u8URL.isEmpty || fileName.isEmpty)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("添加下载")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
