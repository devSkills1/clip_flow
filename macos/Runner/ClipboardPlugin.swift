import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

@objc class ClipboardPlugin: NSObject, FlutterPlugin {
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "clipboard_service", binaryMessenger: registrar.messenger)
        let instance = ClipboardPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getClipboardType":
            getClipboardType(result: result)
        case "getClipboardSequence":
            getClipboardSequence(result: result)
        case "getClipboardFilePaths":
            getClipboardFilePaths(result: result)
        case "getClipboardImageData":
            getClipboardImageData(result: result)
        case "setClipboardImage":
            setClipboardImage(call: call, result: result)
        case "setClipboardFile":
            setClipboardFile(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func getClipboardType(result: @escaping FlutterResult) {
        let pasteboard = NSPasteboard.general
        
        // 检查可用的类型
        let types = pasteboard.types ?? []
        
        var clipboardInfo: [String: Any] = [:]
        
        // 按优先级检查类型
        if types.contains(.fileURL) {
            // 文件类型
            if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [NSURL] {
                let filePaths = fileURLs.compactMap { $0.path }
                if !filePaths.isEmpty {
                    let firstPath = filePaths[0]
                    let fileType = detectFileType(path: firstPath)
                    clipboardInfo = [
                        "type": "file",
                        "subType": fileType,
                        "content": filePaths,
                        "primaryPath": firstPath
                    ]
                }
            }
        } else if types.contains(.tiff) || types.contains(.png) {
            // 图片类型
            var imageData: Data?
            var imageFormat = "unknown"
            
            if let tiffData = pasteboard.data(forType: .tiff) {
                imageData = tiffData
                imageFormat = "tiff"
            } else if let pngData = pasteboard.data(forType: .png) {
                imageData = pngData
                imageFormat = "png"
            }
            
            if let data = imageData {
                clipboardInfo = [
                    "type": "image",
                    "subType": imageFormat,
                    "size": data.count,
                    "hasData": true
                ]
            }
        } else if types.contains(.string) {
            // 文本类型
            if let string = pasteboard.string(forType: .string) {
                let textType = detectTextType(text: string)
                clipboardInfo = [
                    "type": "text",
                    "subType": textType,
                    "content": string,
                    "length": string.count
                ]
            }
        } else if types.contains(.rtf) {
            // 富文本类型
            if let rtfData = pasteboard.data(forType: .rtf) {
                clipboardInfo = [
                    "type": "text",
                    "subType": "rtf",
                    "size": rtfData.count,
                    "hasData": true
                ]
            }
        } else if types.contains(.html) {
            // HTML 类型
            if let htmlData = pasteboard.data(forType: .html) {
                clipboardInfo = [
                    "type": "text",
                    "subType": "html",
                    "size": htmlData.count,
                    "hasData": true
                ]
            }
        } else {
            // 未知类型
            clipboardInfo = [
                "type": "unknown",
                "availableTypes": types.map { $0.rawValue }
            ]
        }
        
        result(clipboardInfo)
    }
    
    private func getClipboardSequence(result: @escaping FlutterResult) {
        let pasteboard = NSPasteboard.general
        result(pasteboard.changeCount)
    }
    
    private func getClipboardFilePaths(result: @escaping FlutterResult) {
        let pasteboard = NSPasteboard.general
        
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [NSURL] {
            let filePaths = fileURLs.compactMap { $0.path }
            result(filePaths)
        } else {
            result(nil)
        }
    }
    
    private func getClipboardImageData(result: @escaping FlutterResult) {
        let pasteboard = NSPasteboard.general
        
        var imageData: Data?
        
        // 按优先级尝试获取图片数据
        if let pngData = pasteboard.data(forType: .png) {
            imageData = pngData
        } else if let tiffData = pasteboard.data(forType: .tiff) {
            imageData = tiffData
        }
        
        if let data = imageData {
            result(FlutterStandardTypedData(bytes: data))
        } else {
            result(nil)
        }
    }
    
    private func detectFileType(path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension.lowercased()
        
        // 图片文件
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "tif", "svg", "ico", "heic", "heif"]
        if imageExtensions.contains(pathExtension) {
            return "image"
        }
        
        // 音频文件
        let audioExtensions = ["mp3", "wav", "aac", "flac", "ogg", "m4a", "wma", "aiff", "au"]
        if audioExtensions.contains(pathExtension) {
            return "audio"
        }
        
        // 视频文件
        let videoExtensions = ["mp4", "avi", "mov", "wmv", "flv", "webm", "mkv", "m4v", "3gp", "ts"]
        if videoExtensions.contains(pathExtension) {
            return "video"
        }
        
        // 文档文件
        let documentExtensions = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "pages", "numbers", "keynote"]
        if documentExtensions.contains(pathExtension) {
            return "document"
        }
        
        // 压缩文件
        let archiveExtensions = ["zip", "rar", "7z", "tar", "gz", "bz2", "xz"]
        if archiveExtensions.contains(pathExtension) {
            return "archive"
        }
        
        // 代码文件
        let codeExtensions = ["swift", "dart", "js", "ts", "py", "java", "cpp", "c", "h", "m", "mm", "go", "rs", "php", "rb", "kt"]
        if codeExtensions.contains(pathExtension) {
            return "code"
        }
        
        return "file"
    }
    
    private func detectTextType(text: String) -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查是否是颜色值
        if isColorValue(text: trimmedText) {
            return "color"
        }
        
        // 检查是否是 URL
        if isURL(text: trimmedText) {
            return "url"
        }
        
        // 检查是否是邮箱
        if isEmail(text: trimmedText) {
            return "email"
        }
        
        // 检查是否是文件路径
        if isFilePath(text: trimmedText) {
            return "path"
        }
        
        // 检查是否是 JSON
        if isJSON(text: trimmedText) {
            return "json"
        }
        
        // 检查是否是 XML/HTML
        if isXMLOrHTML(text: trimmedText) {
            return "markup"
        }
        
        return "plain"
    }
    
    private func isColorValue(text: String) -> Bool {
        // 十六进制颜色
        let hexPattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3}|[A-Fa-f0-9]{8})$"
        if text.range(of: hexPattern, options: .regularExpression) != nil {
            return true
        }
        
        // RGB/RGBA
        let rgbPattern = "^rgba?\\s*\\(\\s*\\d+\\s*,\\s*\\d+\\s*,\\s*\\d+\\s*(,\\s*[0-9.]+)?\\s*\\)$"
        if text.range(of: rgbPattern, options: .regularExpression) != nil {
            return true
        }
        
        // HSL/HSLA
        let hslPattern = "^hsla?\\s*\\(\\s*\\d+\\s*,\\s*\\d+%\\s*,\\s*\\d+%\\s*(,\\s*[0-9.]+)?\\s*\\)$"
        if text.range(of: hslPattern, options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
    
    private func isURL(text: String) -> Bool {
        if let url = URL(string: text), url.scheme != nil {
            return true
        }
        return false
    }
    
    private func isEmail(text: String) -> Bool {
        let emailPattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return text.range(of: emailPattern, options: .regularExpression) != nil
    }
    
    private func isFilePath(text: String) -> Bool {
        return text.hasPrefix("file://") || text.contains("/") || text.contains("\\")
    }
    
    private func isJSON(text: String) -> Bool {
        guard let data = text.data(using: .utf8) else { return false }
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            return true
        } catch {
            return false
        }
    }
    
    private func isXMLOrHTML(text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("<") && trimmed.hasSuffix(">")
    }
    
    private func setClipboardImage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imageData = args["imageData"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid image data", details: nil))
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let data = imageData.data
        pasteboard.setData(data, forType: .png)
        
        result(true)
    }
    
    private func setClipboardFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid file path", details: nil))
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // 创建文件URL
        let fileURL = URL(fileURLWithPath: filePath)
        
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: filePath) else {
            result(FlutterError(code: "FILE_NOT_FOUND", message: "File does not exist: \(filePath)", details: nil))
            return
        }
        
        // 使用正确的方式将文件写入剪贴板
        // 方法1: 使用 NSFilenamesPboardType (传统方法)
        pasteboard.setPropertyList([filePath], forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType"))
        
        // 方法2: 同时使用现代的 fileURL 类型
        pasteboard.setPropertyList([fileURL.absoluteString], forType: .fileURL)
        
        // 方法3: 对于图片文件，同时设置图片数据
        let fileExtension = fileURL.pathExtension.lowercased()
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "tif", "svg", "ico", "heic", "heif"]
        if imageExtensions.contains(fileExtension) {
            if let imageData = try? Data(contentsOf: fileURL) {
                pasteboard.setData(imageData, forType: .png)
            }
        }
        
        result(true)
    }
}