import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers
import Vision
import ServiceManagement

@objc class ClipboardPlugin: NSObject, FlutterPlugin {
    // 全局事件监听器
    private var globalEventMonitor: Any?
    
    // 快捷键信息结构
    private struct HotkeyInfo {
        let keyCode: UInt16
        let modifiers: NSEvent.ModifierFlags
        let ignoreRepeat: Bool
    }
    
    // 注册的快捷键
    private var registeredHotkeys: [String: HotkeyInfo] = [:]
    
    // Flutter方法通道
    private var channel: FlutterMethodChannel?
    
    // Security-Scoped Bookmarks 访问缓存
    private var accessingBookmarks: [String: URL] = [:]
    
    // 权限缓存机制
    private var lastClipboardSequence: Int = -1
    private var lastSequenceCheckTime: Date = Date.distantPast
    private let sequenceCacheInterval: TimeInterval = 0.5 // 500ms 缓存间隔
    
    // 类型缓存机制
    private var lastClipboardType: [String: Any]?
    private var lastTypeCheckTime: Date = Date.distantPast
    private var lastTypeSequence: Int = -1
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "clipboard_service", binaryMessenger: registrar.messenger)
        let instance = ClipboardPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "test":
            result("ClipboardPlugin is working on macOS")
        case "getClipboardType":
            getClipboardType(result: result)
        case "getClipboardSequence":
            getClipboardSequence(result: result)
        case "getClipboardFilePaths":
            getClipboardFilePaths(result: result)
        case "getClipboardImageData":
            getClipboardImageData(result: result)
        case "getClipboardImage":
            getClipboardImageData(result: result)
        case "getRichTextData":
            getRichTextData(call: call, result: result)
        case "setClipboardImage":
            setClipboardImage(call: call, result: result)
        case "setClipboardFile":
            setClipboardFile(call: call, result: result)
        case "performOCR":
            performOCR(call: call, result: result)
        case "isOCRAvailable":
            isOCRAvailable(result: result)
        case "getSupportedOCRLanguages":
            getSupportedOCRLanguages(result: result)
        case "isHotkeySupported":
            isHotkeySupported(result: result)
        case "registerHotkey":
            registerHotkey(call: call, result: result)
        case "unregisterHotkey":
            unregisterHotkey(call: call, result: result)
        case "isSystemHotkey":
            isSystemHotkey(call: call, result: result)
        case "isAutostartEnabled":
            isAutostartEnabled(result: result)
        case "enableAutostart":
            enableAutostart(result: result)
        case "disableAutostart":
            disableAutostart(result: result)
        case "pickDirectoryForBookmark":
            pickDirectoryForBookmark(call: call, result: result)
        case "startBookmarkAccess":
            startBookmarkAccess(call: call, result: result)
        case "stopBookmarkAccess":
            stopBookmarkAccess(call: call, result: result)
        case "removeBookmark":
            removeBookmark(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getClipboardType(result: @escaping FlutterResult) {
        let pasteboard = NSPasteboard.general
        let currentSequence = pasteboard.changeCount
        let now = Date()
        
        // 如果剪贴板内容没有变化且缓存有效，直接返回缓存
        if let cachedType = lastClipboardType,
           currentSequence == lastTypeSequence,
           now.timeIntervalSince(lastTypeCheckTime) < sequenceCacheInterval {
            result(cachedType)
            return
        }

        // 检查可用的类型
        let types = pasteboard.types ?? []

        var clipboardInfo: [String: Any] = [:]

        // 按优先级检查类型 - 富文本优先
        if types.contains(.rtf) {
            // RTF 富文本类型 - 最高优先级
            if let rtfData = pasteboard.data(forType: .rtf) {
                if let rtfString = String(data: rtfData, encoding: .utf8) {
                    clipboardInfo = [
                        "type": "rtf",
                        "content": rtfString,
                        "size": rtfData.count,
                        "hasData": true,
                        "priority": "high"
                    ]
                } else {
                    clipboardInfo = [
                        "type": "rtf",
                        "size": rtfData.count,
                        "hasData": true,
                        "priority": "high"
                    ]
                }
            }
        } else if types.contains(.html) {
            // HTML 类型 - 第二优先级
            if let htmlData = pasteboard.data(forType: .html) {
                if let htmlString = String(data: htmlData, encoding: .utf8) {
                    clipboardInfo = [
                        "type": "html",
                        "content": htmlString,
                        "size": htmlData.count,
                        "hasData": true,
                        "priority": "high"
                    ]
                } else {
                    clipboardInfo = [
                        "type": "html",
                        "size": htmlData.count,
                        "hasData": true,
                        "priority": "high"
                    ]
                }
            }
        } else if types.contains(.fileURL) {
            // 文件类型 - 第三优先级
            if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil)
                as? [NSURL]
            {
                let filePaths = fileURLs.compactMap { $0.path }
                if !filePaths.isEmpty {
                    let firstPath = filePaths[0]
                    let fileType = detectFileType(path: firstPath)
                    clipboardInfo = [
                        "type": "file",
                        "content": filePaths,
                        "primaryPath": firstPath,
                        "hasData": true,
                        "priority": "medium"
                    ]
                }
            }
        } else if types.contains(.tiff) || types.contains(.png)
            || types.contains(NSPasteboard.PasteboardType("public.jpeg"))
            || types.contains(NSPasteboard.PasteboardType("public.image"))
            || types.contains(NSPasteboard.PasteboardType("com.compuserve.gif"))
            || types.contains(NSPasteboard.PasteboardType("com.microsoft.bmp"))
            || types.contains(NSPasteboard.PasteboardType("org.webmproject.webp"))
            || types.contains(NSPasteboard.PasteboardType("public.heic"))
            || types.contains(NSPasteboard.PasteboardType("public.heif"))
            || _hasAnyImageType(types: types)
        {
            // 图片类型
            var imageData: Data?
            var imageFormat = "unknown"

            if let pngData = pasteboard.data(forType: .png) {
                imageData = pngData
                imageFormat = "png"
            } else if let tiffData = pasteboard.data(forType: .tiff) {
                imageData = tiffData
                imageFormat = "tiff"
            } else if let jpegData = pasteboard.data(
                forType: NSPasteboard.PasteboardType("public.jpeg"))
            {
                imageData = jpegData
                imageFormat = "jpeg"
            } else if let gifData = pasteboard.data(
                forType: NSPasteboard.PasteboardType("com.compuserve.gif"))
            {
                imageData = gifData
                imageFormat = "gif"
            } else if let bmpData = pasteboard.data(
                forType: NSPasteboard.PasteboardType("com.microsoft.bmp"))
            {
                imageData = bmpData
                imageFormat = "bmp"
            } else if let webpData = pasteboard.data(
                forType: NSPasteboard.PasteboardType("org.webmproject.webp"))
            {
                imageData = webpData
                imageFormat = "webp"
            } else if let heicData = pasteboard.data(
                forType: NSPasteboard.PasteboardType("public.heic"))
            {
                imageData = heicData
                imageFormat = "heic"
            } else if let heifData = pasteboard.data(
                forType: NSPasteboard.PasteboardType("public.heif"))
            {
                imageData = heifData
                imageFormat = "heif"
            }

            if let data = imageData {
                clipboardInfo = [
                    "type": "image",
                    "size": data.count,
                    "hasData": true,
                    "priority": "medium"
                ]
            }
        } else if types.contains(.string) {
            // 文本类型 - 最低优先级（细分判定交由 Dart 层处理）
            if let string = pasteboard.string(forType: .string) {
                clipboardInfo = [
                    "type": "text",
                    "length": string.count,
                    "hasData": true,
                    "priority": "low"
                ]
            }
        } else {
            // 未知类型
            clipboardInfo = [
                "type": "unknown",
                "availableTypes": types.map { $0.rawValue },
            ]
        }

        // 更新缓存
        lastClipboardType = clipboardInfo
        lastTypeCheckTime = now
        lastTypeSequence = currentSequence
        
        result(clipboardInfo)
    }

    private func getClipboardSequence(result: @escaping FlutterResult) {
        let now = Date()
        
        // 如果距离上次检查时间小于缓存间隔，直接返回缓存的值
        if now.timeIntervalSince(lastSequenceCheckTime) < sequenceCacheInterval && lastClipboardSequence != -1 {
            result(lastClipboardSequence)
            return
        }
        
        // 更新缓存
        let pasteboard = NSPasteboard.general
        lastClipboardSequence = pasteboard.changeCount
        lastSequenceCheckTime = now
        
        result(lastClipboardSequence)
    }

    private func getClipboardFilePaths(result: @escaping FlutterResult) {
        let pasteboard = NSPasteboard.general

        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [NSURL]
        {
            let filePaths = fileURLs.compactMap { $0.path }
            result(filePaths)
        } else {
            result(nil)
        }
    }

    private func getClipboardImageData(result: @escaping FlutterResult) {
        let pasteboard = NSPasteboard.general
        let types = pasteboard.types ?? []

        NSLog("ClipboardPlugin: Available pasteboard types: %@", types.map { $0.rawValue })

        var imageData: Data?
        var foundType: String?

        // 按优先级尝试获取图片数据
        if let pngData = pasteboard.data(forType: .png) {
            imageData = pngData
            foundType = "png"
        } else if let tiffData = pasteboard.data(forType: .tiff) {
            imageData = tiffData
            foundType = "tiff"
        } else if let jpegData = pasteboard.data(
            forType: NSPasteboard.PasteboardType("public.jpeg"))
        {
            imageData = jpegData
            foundType = "jpeg"
        } else if let genericImage = pasteboard.data(
            forType: NSPasteboard.PasteboardType("public.image"))
        {
            imageData = genericImage
            foundType = "public.image"
        } else if let gifData = pasteboard.data(
            forType: NSPasteboard.PasteboardType("com.compuserve.gif"))
        {
            imageData = gifData
            foundType = "gif"
        } else if let bmpData = pasteboard.data(
            forType: NSPasteboard.PasteboardType("com.microsoft.bmp"))
        {
            imageData = bmpData
            foundType = "bmp"
        } else if let webpData = pasteboard.data(
            forType: NSPasteboard.PasteboardType("org.webmproject.webp"))
        {
            imageData = webpData
            foundType = "webp"
        } else if let heicData = pasteboard.data(
            forType: NSPasteboard.PasteboardType("public.heic"))
        {
            imageData = heicData
            foundType = "heic"
        } else if let heifData = pasteboard.data(
            forType: NSPasteboard.PasteboardType("public.heif"))
        {
            imageData = heifData
            foundType = "heif"
        } else {
            // 尝试其他可能的图片类型
            imageData = _tryGetAnyImageData(from: pasteboard)
            if imageData != nil {
                foundType = "other"
            }
        }

        if let data = imageData, let type = foundType {
            NSLog(
                "ClipboardPlugin: Found image data of type %@ with size %d bytes", type, data.count)
            result(FlutterStandardTypedData(bytes: data))
        } else {
            NSLog("ClipboardPlugin: No image data found")
            result(nil)
        }
    }

    private func getRichTextData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let type = args["type"] as? String
        else {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENT", message: "Invalid type parameter", details: nil))
            return
        }

        let pasteboard = NSPasteboard.general

        switch type.lowercased() {
        case "rtf":
            if let rtfData = pasteboard.data(forType: .rtf) {
                if let rtfString = String(data: rtfData, encoding: .utf8) {
                    NSLog("ClipboardPlugin: Found RTF data (%d bytes)", rtfData.count)
                    result(rtfString)
                } else {
                    NSLog("ClipboardPlugin: Failed to decode RTF data")
                    result(nil)
                }
            } else {
                result(nil)
            }
        case "html":
            if let htmlData = pasteboard.data(forType: .html) {
                if let htmlString = String(data: htmlData, encoding: .utf8) {
                    NSLog("ClipboardPlugin: Found HTML data (%d bytes)", htmlData.count)
                    result(htmlString)
                } else {
                    NSLog("ClipboardPlugin: Failed to decode HTML data")
                    result(nil)
                }
            } else {
                result(nil)
            }
        default:
            result(
                FlutterError(
                    code: "UNSUPPORTED_TYPE", message: "Unsupported rich text type: \(type)",
                    details: nil))
        }
    }

    private func detectFileType(path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension.lowercased()

        // 图片文件
        let imageExtensions = [
            "png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "tif", "svg", "ico", "heic", "heif",
        ]
        if imageExtensions.contains(pathExtension) {
            return "image"
        }

        // 音频文件
        let audioExtensions = ["mp3", "wav", "aac", "flac", "ogg", "m4a", "wma", "aiff", "au"]
        if audioExtensions.contains(pathExtension) {
            return "audio"
        }

        // 视频文件
        let videoExtensions = [
            "mp4", "avi", "mov", "wmv", "flv", "webm", "mkv", "m4v", "3gp", "ts",
        ]
        if videoExtensions.contains(pathExtension) {
            return "video"
        }

        // 文档文件
        let documentExtensions = [
            "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "pages", "numbers",
            "keynote",
        ]
        if documentExtensions.contains(pathExtension) {
            return "document"
        }

        // 压缩文件
        let archiveExtensions = ["zip", "rar", "7z", "tar", "gz", "bz2", "xz"]
        if archiveExtensions.contains(pathExtension) {
            return "archive"
        }

        // 代码文件
        let codeExtensions = [
            "swift", "dart", "js", "ts", "py", "java", "cpp", "c", "h", "m", "mm", "go", "rs",
            "php", "rb", "kt",
        ]
        if codeExtensions.contains(pathExtension) {
            return "code"
        }

        return "file"
    }

    // 说明：细粒度文本/颜色判定已收敛到 Dart 层；
    // 本方法保留但不再在原生侧被调用，仅供参考/后续清理。
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

    // 说明：颜色值判断逻辑已迁移至 Dart 的 ColorUtils；
    // 原生侧保留此方法但不参与运行时分类。
    private func isColorValue(text: String) -> Bool {
        // 十六进制颜色（与Dart端保持一致，支持可选的#号和4位颜色）
        let hexPattern = "^#?(?:[A-Fa-f0-9]{3}|[A-Fa-f0-9]{4}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$"
        if text.range(of: hexPattern, options: .regularExpression) != nil {
            return true
        }

        // RGB颜色（严格匹配0-255范围）
        let rgbPattern =
            "^rgb\\s*\\(\\s*(0|255|25[0-4]|2[0-4]\\d|[01]?\\d\\d?)\\s*,\\s*(0|255|25[0-4]|2[0-4]\\d|[01]?\\d\\d?)\\s*,\\s*(0|255|25[0-4]|2[0-4]\\d|[01]?\\d\\d?)\\s*\\)$"
        if text.range(of: rgbPattern, options: .regularExpression) != nil {
            return true
        }

        // RGBA颜色（alpha值0-1）
        let rgbaPattern =
            "^rgba\\s*\\(\\s*(0|255|25[0-4]|2[0-4]\\d|[01]?\\d\\d?)\\s*,\\s*(0|255|25[0-4]|2[0-4]\\d|[01]?\\d\\d?)\\s*,\\s*(0|255|25[0-4]|2[0-4]\\d|[01]?\\d\\d?)\\s*,\\s*(0|1|0\\.[0-9]+|1\\.0)\\s*\\)$"
        if text.range(of: rgbaPattern, options: .regularExpression) != nil {
            return true
        }

        // HSL颜色（角度0-360，百分比0-100%）
        let hslPattern =
            "^hsl\\s*\\(\\s*(360|3[0-5]\\d|[0-2]?\\d\\d?)\\s*,\\s*(100%|\\d{1,2}%)\\s*,\\s*(100%|\\d{1,2}%)\\s*\\)$"
        if text.range(of: hslPattern, options: .regularExpression) != nil {
            return true
        }

        // HSLA颜色（含透明度）
        let hslaPattern =
            "^hsla\\s*\\(\\s*(360|3[0-5]\\d|[0-2]?\\d\\d?)\\s*,\\s*(100%|\\d{1,2}%)\\s*,\\s*(100%|\\d{1,2}%)\\s*,\\s*(0|1|0\\.[0-9]+|1\\.0)\\s*\\)$"
        if text.range(of: hslaPattern, options: .regularExpression) != nil {
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
            let imageData = args["imageData"] as? FlutterStandardTypedData
        else {
            result(
                FlutterError(code: "INVALID_ARGUMENT", message: "Invalid image data", details: nil))
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
            let filePath = args["filePath"] as? String
        else {
            result(
                FlutterError(code: "INVALID_ARGUMENT", message: "Invalid file path", details: nil))
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // 创建文件URL
        let fileURL = URL(fileURLWithPath: filePath)

        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: filePath) else {
            result(
                FlutterError(
                    code: "FILE_NOT_FOUND", message: "File does not exist: \(filePath)",
                    details: nil))
            return
        }

        // 使用正确的方式将文件写入剪贴板
        // 方法1: 使用 NSFilenamesPboardType (传统方法)
        pasteboard.setPropertyList(
            [filePath], forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType"))

        // 方法2: 同时使用现代的 fileURL 类型
        pasteboard.setPropertyList([fileURL.absoluteString], forType: .fileURL)

        // 方法3: 对于图片文件，同时设置图片数据
        let fileExtension = fileURL.pathExtension.lowercased()
        let imageExtensions = [
            "png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "tif", "svg", "ico", "heic", "heif",
        ]
        if imageExtensions.contains(fileExtension) {
            if let imageData = try? Data(contentsOf: fileURL) {
                pasteboard.setData(imageData, forType: .png)
            }
        }

        result(true)
    }

    // 辅助方法：检查是否有任何图片类型
    private func _hasAnyImageType(types: [NSPasteboard.PasteboardType]) -> Bool {
        let imageTypes = [
            "public.image",
            "public.jpeg-2000",
            "public.camera-raw-image",
            "com.adobe.photoshop-image",
            "com.truevision.tga-image",
            "public.radiance",
            "public.pbm",
            "public.pvr",
            "com.ilm.openexr-image",
        ]

        for typeName in imageTypes {
            let type = NSPasteboard.PasteboardType(typeName)
            if types.contains(type) {
                NSLog("ClipboardPlugin: Found additional image type: %@", typeName)
                return true
            }
        }
        return false
    }

    // 辅助方法：尝试获取任何图片数据
    private func _tryGetAnyImageData(from pasteboard: NSPasteboard) -> Data? {
        let additionalImageTypes = [
            "public.image",
            "public.jpeg-2000",
            "public.camera-raw-image",
            "com.adobe.photoshop-image",
            "com.truevision.tga-image",
            "public.radiance",
            "public.pbm",
            "public.pvr",
            "com.ilm.openexr-image",
        ]

        for typeName in additionalImageTypes {
            let type = NSPasteboard.PasteboardType(typeName)
            if let data = pasteboard.data(forType: type), !data.isEmpty {
                NSLog(
                    "ClipboardPlugin: Found image data in additional type: %@ (%d bytes)", typeName,
                    data.count)
                return data
            }
        }

        NSLog("ClipboardPlugin: No additional image types found")
        return nil
    }
    
    // MARK: - OCR Methods
    
    private func performOCR(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imageData = args["imageData"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing imageData parameter", details: nil))
            return
        }

        NSLog("ClipboardPlugin: Starting OCR on image data (%d bytes)", imageData.data.count)
        
        // 创建NSImage
        guard let nsImage = NSImage(data: imageData.data) else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Cannot create NSImage from data", details: nil))
            return
        }
        
        // 转换为CGImage
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Cannot create CGImage from NSImage", details: nil))
            return
        }
        
        // 可选的最小置信度过滤（需在闭包外声明以便捕获）
        let minConfidence = (args["minConfidence"] as? Double) ?? 0.0

        // 创建Vision文字识别请求
        let request = VNRecognizeTextRequest { (request, error) in
            DispatchQueue.main.async {
                if let error = error {
                    NSLog("ClipboardPlugin: OCR error: %@", error.localizedDescription)
                    result(FlutterError(code: "OCR_ERROR", message: error.localizedDescription, details: nil))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    NSLog("ClipboardPlugin: No text observations found")
                    result(["text": "", "confidence": 0.0])
                    return
                }
                
                var recognizedText = ""
                var totalConfidence: Float = 0.0
                var observationCount = 0
                let threshold: Float = Float(minConfidence)
                
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    // 置信度过滤
                    if topCandidate.confidence >= threshold {
                        recognizedText += topCandidate.string + "\n"
                        totalConfidence += topCandidate.confidence
                        observationCount += 1
                        NSLog("ClipboardPlugin: Recognized text: '%@' (confidence: %.2f)", 
                              topCandidate.string, topCandidate.confidence)
                    } else {
                        NSLog("ClipboardPlugin: Skipped low-confidence text: '%.2f' < '%.2f'", 
                              topCandidate.confidence, threshold)
                    }
                }
                
                // 移除最后的换行符
                if recognizedText.hasSuffix("\n") {
                    recognizedText = String(recognizedText.dropLast())
                }
                
                let averageConfidence = observationCount > 0 ? totalConfidence / Float(observationCount) : 0.0
                
                NSLog("ClipboardPlugin: OCR completed. Text: '%@', Average confidence: %.2f", 
                      recognizedText, averageConfidence)
                
                result([
                    "text": recognizedText,
                    "confidence": Double(averageConfidence)
                ])
            }
        }
        
        // 配置OCR请求
        request.recognitionLevel = .accurate
        // 处理语言参数
        let langParam = (args["language"] as? String) ?? "auto"
        if langParam == "auto" {
            request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant"]
        } else {
            request.recognitionLanguages = [langParam]
        }
        request.usesLanguageCorrection = true
        
        // 执行OCR请求
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    NSLog("ClipboardPlugin: Failed to perform OCR: %@", error.localizedDescription)
                    result(FlutterError(code: "OCR_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    /// 检查 OCR 是否可用
    private func isOCRAvailable(result: @escaping FlutterResult) {
        if #available(macOS 10.15, *) {
            result(true)
        } else {
            result(false)
        }
    }

    /// 返回系统支持的 OCR 语言列表
    private func getSupportedOCRLanguages(result: @escaping FlutterResult) {
        if #available(macOS 10.15, *) {
            do {
                var langs: [String]
                if #available(macOS 11.0, *) {
                    langs = try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: VNRecognizeTextRequestRevision2)
                } else {
                    // 在 macOS 10.15 上使用 Revision1 以避免可用性编译错误
                    langs = try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: VNRecognizeTextRequestRevision1)
                }
                result(langs)
            } catch {
                result(FlutterError(code: "LANG_QUERY_FAILED", message: error.localizedDescription, details: nil))
            }
        } else {
            result(["en-US", "zh-Hans", "zh-Hant"]) // 基本回退
        }
    }
    
    // MARK: - Hotkey Support
    
    /// 检查是否支持全局快捷键
    private func isHotkeySupported(result: @escaping FlutterResult) {
        // macOS 支持全局快捷键
        result(true)
    }
    
    /// 注册快捷键
    private func registerHotkey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let action = args["action"] as? String,
              let keyString = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
            return
        }
        let ignoreRepeat = (args["ignoreRepeat"] as? Bool) ?? true
        
        // 解析快捷键字符串 (例如: "Cmd+Shift+C")
        let components = keyString.components(separatedBy: "+")
        
        // 校验仅存在一个主键
        let modifierSet: Set<String> = ["cmd", "ctrl", "alt", "shift", "meta", "option"]
        let mainKeys = components.filter { !modifierSet.contains($0.lowercased()) }
        guard mainKeys.count == 1 else {
            result(FlutterError(code: "INVALID_KEY", message: "Invalid key combination", details: ["mainKeys": mainKeys]))
            return
        }
        
        guard let keyCode = parseKeyCode(from: components) else {
            result(FlutterError(code: "INVALID_KEY", message: "Invalid key code", details: nil))
            return
        }
        
        let modifiers = parseModifiers(from: components)
        
        // 注册快捷键
        let success = registerGlobalHotkey(action: action, keyCode: keyCode, modifiers: modifiers, ignoreRepeat: ignoreRepeat)
        result(success)
    }
    
    /// 取消注册快捷键
    private func unregisterHotkey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let action = args["action"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid action", details: nil))
            return
        }
        
        let success = unregisterGlobalHotkey(action: action)
        result(success)
    }
    
    /// 检查是否为系统快捷键
    private func isSystemHotkey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let keyString = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid key string", details: nil))
            return
        }
        
        // 简单的系统快捷键检查
        let systemHotkeys = [
            "Cmd+Q", "Cmd+W", "Cmd+Tab", "Cmd+Space",
            "Cmd+C", "Cmd+V", "Cmd+X", "Cmd+Z", "Cmd+Y"
        ]
        
        let isSystem = systemHotkeys.contains(keyString)
        result(isSystem)
    }
    
    // MARK: - Modern Hotkey Implementation
    
    /// 注册全局快捷键（使用NSEvent监听）
    private func registerGlobalHotkey(action: String, keyCode: UInt16, modifiers: NSEvent.ModifierFlags, ignoreRepeat: Bool) -> Bool {
        // 取消之前的注册并处理返回值
        let unregOk = unregisterGlobalHotkey(action: action)
        if !unregOk {
            NSLog("ClipboardPlugin: Failed to unregister previous hotkey for action %@", action)
        }

        // 保存快捷键配置
        registeredHotkeys[action] = HotkeyInfo(keyCode: keyCode, modifiers: modifiers, ignoreRepeat: ignoreRepeat)

        // 如果这是第一个快捷键，启动全局监听器
        if globalEventMonitor == nil {
            setupGlobalEventMonitor()
        }
        
        return true
    }
    
    /// 取消注册全局快捷键
    private func unregisterGlobalHotkey(action: String) -> Bool {
        registeredHotkeys.removeValue(forKey: action)
        
        // 如果没有注册的快捷键了，停止全局监听器
        if registeredHotkeys.isEmpty && globalEventMonitor != nil {
            NSEvent.removeMonitor(globalEventMonitor!)
            globalEventMonitor = nil
        }
        
        return true
    }
    
    /// 设置全局事件监听器
    private func setupGlobalEventMonitor() {
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
        }
    }
    
    /// 处理全局按键事件
    private func handleGlobalKeyEvent(_ event: NSEvent) {
        let keyCode = event.keyCode
        let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        
        // 检查是否匹配任何注册的快捷键
        for (action, hotkey) in registeredHotkeys {
            if hotkey.ignoreRepeat && event.isARepeat { continue }
            if keyCode == hotkey.keyCode && modifiers == hotkey.modifiers {
                // 通知Flutter端
                DispatchQueue.main.async { [weak self] in
                    self?.channel?.invokeMethod("onHotkeyPressed", arguments: ["action": action])
                }
                break
            }
        }
    }
    
    /// 解析按键代码
    private func parseKeyCode(from components: [String]) -> UInt16? {
        let keyComponent = components.last?.lowercased()
        
        switch keyComponent {
        case "a": return 0x00
        case "s": return 0x01
        case "d": return 0x02
        case "f": return 0x03
        case "h": return 0x04
        case "g": return 0x05
        case "z": return 0x06
        case "x": return 0x07
        case "c": return 0x08
        case "v": return 0x09
        case "b": return 0x0B
        case "q": return 0x0C
        case "w": return 0x0D
        case "e": return 0x0E
        case "r": return 0x0F
        case "y": return 0x10
        case "t": return 0x11
        case "1": return 0x12
        case "2": return 0x13
        case "3": return 0x14
        case "4": return 0x15
        case "6": return 0x16
        case "5": return 0x17
        case "=": return 0x18
        case "9": return 0x19
        case "7": return 0x1A
        case "-": return 0x1B
        case "8": return 0x1C
        case "0": return 0x1D
        case "]": return 0x1E
        case "o": return 0x1F
        case "u": return 0x20
        case "[": return 0x21
        case "i": return 0x22
        case "p": return 0x23
        case "l": return 0x25
        case "j": return 0x26
        case "'": return 0x27
        case "k": return 0x28
        case ";": return 0x29
        case "\\": return 0x2A
        case ",": return 0x2B
        case "/": return 0x2C
        case "n": return 0x2D
        case "m": return 0x2E
        case ".": return 0x2F
        case "`": return 0x32
        case "space": return 0x31
        case "delete": return 0x33
        case "escape": return 0x35
        case "enter": return 0x24
        case "tab": return 0x30
        default: return nil
        }
    }
    
    /// 解析修饰键
    private func parseModifiers(from components: [String]) -> NSEvent.ModifierFlags {
        var modifiers: NSEvent.ModifierFlags = []
        
        for component in components {
            switch component.lowercased() {
            case "cmd", "command": modifiers.insert(.command)
            case "shift": modifiers.insert(.shift)
            case "option", "alt": modifiers.insert(.option)
            case "control", "ctrl": modifiers.insert(.control)
            default: break
            }
        }
        
        return modifiers
    }
    
    // MARK: - 开机自启动功能
    
    /// 检查是否启用了开机自启动
    private func isAutostartEnabled(result: @escaping FlutterResult) {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            result(status == .enabled)
            return
        }
        // 旧版系统回退到 LaunchAgents 检查
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.example.clip_flow_pro"
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let launchAgentsPath = homeDirectory.appendingPathComponent("Library/LaunchAgents")
        let plistPath = launchAgentsPath.appendingPathComponent("\(bundleIdentifier).plist")
        let isEnabled = FileManager.default.fileExists(atPath: plistPath.path)
        result(isEnabled)
    }
    
    /// 启用开机自启动
    private func enableAutostart(result: @escaping FlutterResult) {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                result(true)
                return
            } catch {
                NSLog("SMAppService register failed: %@", error.localizedDescription)
                result(FlutterError(code: "SM_REGISTER_FAILED", message: error.localizedDescription, details: nil))
                return
            }
        }
        // 旧版系统回退到 LaunchAgents
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.example.clip_flow_pro"
        let appPath = Bundle.main.bundlePath
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let launchAgentsPath = homeDirectory.appendingPathComponent("Library/LaunchAgents")
        do {
            try FileManager.default.createDirectory(at: launchAgentsPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            NSLog("创建 LaunchAgents 目录失败: %@", error.localizedDescription)
            result(FlutterError(code: "LAUNCH_AGENTS_DIR_FAILED", message: error.localizedDescription, details: nil))
            return
        }
        let plistPath = launchAgentsPath.appendingPathComponent("\(bundleIdentifier).plist")
        let plistContent = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
        <plist version=\"1.0\">
        <dict>
            <key>Label</key>
            <string>\(bundleIdentifier)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(appPath)/Contents/MacOS/clip_flow_pro</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
        </dict>
        </plist>
        """
        do {
            try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)
            let task = Process()
            task.launchPath = "/bin/launchctl"
            task.arguments = ["load", plistPath.path]
            task.launch()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                result(true)
            } else {
                result(FlutterError(code: "LAUNCHCTL_LOAD_FAILED", message: "launchctl load failed", details: task.terminationStatus))
            }
        } catch {
            NSLog("创建开机自启动配置失败: %@", error.localizedDescription)
            result(FlutterError(code: "CREATE_PLIST_FAILED", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Files & Folders 权限：安全书签

    /// 让用户选择目录并创建持久化安全书签（需要 entitlements: app-scope bookmarks）
    private func pickDirectoryForBookmark(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'key'", details: nil))
            return
        }
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.prompt = "选择"
            panel.message = "请选择需要授权访问的文件夹"
            let response = panel.runModal()
            if response == .OK, let url = panel.url {
                do {
                    let bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                    UserDefaults.standard.set(bookmark, forKey: "bookmark.\(key)")
                    UserDefaults.standard.synchronize()
                    result(["key": key, "path": url.path])
                } catch {
                    result(FlutterError(code: "BOOKMARK_FAILED", message: error.localizedDescription, details: nil))
                }
            } else {
                result(nil)
            }
        }
    }

    /// 开始访问指定安全书签（解析并 startAccessingSecurityScopedResource）
    private func startBookmarkAccess(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'key'", details: nil))
            return
        }
        guard let data = UserDefaults.standard.data(forKey: "bookmark.\(key)") else {
            result(FlutterError(code: "BOOKMARK_NOT_FOUND", message: "Bookmark not found for key: \(key)", details: nil))
            return
        }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                let newData = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(newData, forKey: "bookmark.\(key)")
            }
            if url.startAccessingSecurityScopedResource() {
                accessingBookmarks[key] = url
                result(["key": key, "path": url.path])
            } else {
                result(FlutterError(code: "BOOKMARK_ACCESS_DENIED", message: "Failed to start accessing bookmark for key: \(key)", details: nil))
            }
        } catch {
            result(FlutterError(code: "BOOKMARK_RESOLVE_FAILED", message: error.localizedDescription, details: nil))
        }
    }

    /// 停止访问指定安全书签
    private func stopBookmarkAccess(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'key'", details: nil))
            return
        }
        if let url = accessingBookmarks.removeValue(forKey: key) {
            url.stopAccessingSecurityScopedResource()
            result(true)
        } else {
            result(false)
        }
    }

    /// 删除已保存的安全书签
    private func removeBookmark(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'key'", details: nil))
            return
        }
        if let url = accessingBookmarks.removeValue(forKey: key) {
            url.stopAccessingSecurityScopedResource()
        }
        UserDefaults.standard.removeObject(forKey: "bookmark.\(key)")
        result(true)
    }
    
    /// 禁用开机自启动
    private func disableAutostart(result: @escaping FlutterResult) {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
                result(true)
                return
            } catch {
                NSLog("SMAppService unregister failed: %@", error.localizedDescription)
                result(FlutterError(code: "SM_UNREGISTER_FAILED", message: error.localizedDescription, details: nil))
                return
            }
        }
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.example.clip_flow_pro"
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let launchAgentsPath = homeDirectory.appendingPathComponent("Library/LaunchAgents")
        let plistPath = launchAgentsPath.appendingPathComponent("\(bundleIdentifier).plist")
        if FileManager.default.fileExists(atPath: plistPath.path) {
            let task = Process()
            task.launchPath = "/bin/launchctl"
            task.arguments = ["unload", plistPath.path]
            task.launch()
            task.waitUntilExit()
            do {
                try FileManager.default.removeItem(at: plistPath)
                result(true)
            } catch {
                NSLog("删除开机自启动配置失败: %@", error.localizedDescription)
                result(FlutterError(code: "REMOVE_PLIST_FAILED", message: error.localizedDescription, details: nil))
            }
        } else {
            result(true)
        }
    }
}
