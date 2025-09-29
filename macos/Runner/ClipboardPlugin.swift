import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers
import Vision

@objc class ClipboardPlugin: NSObject, FlutterPlugin {

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "clipboard_service", binaryMessenger: registrar.messenger)
        let instance = ClipboardPlugin()
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
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getClipboardType(result: @escaping FlutterResult) {
        let pasteboard = NSPasteboard.general

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
                        "subType": "richText",
                        "content": rtfString,
                        "size": rtfData.count,
                        "hasData": true,
                        "priority": "high"
                    ]
                } else {
                    clipboardInfo = [
                        "type": "rtf",
                        "subType": "rich_text",
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
                        "subType": "markup",
                        "content": htmlString,
                        "size": htmlData.count,
                        "hasData": true,
                        "priority": "high"
                    ]
                } else {
                    clipboardInfo = [
                        "type": "html",
                        "subType": "markup",
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
                        "subType": fileType,
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
                    "subType": imageFormat,
                    "size": data.count,
                    "hasData": true,
                    "priority": "medium"
                ]
            }
        } else if types.contains(.string) {
            // 文本类型 - 最低优先级
            if let string = pasteboard.string(forType: .string) {
                let textType = detectTextType(text: string)
                clipboardInfo = [
                    "type": "text",
                    "subType": textType,
                    "content": string,
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

        result(clipboardInfo)
    }

    private func getClipboardSequence(result: @escaping FlutterResult) {
        let pasteboard = NSPasteboard.general
        result(pasteboard.changeCount)
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
        
        // 创建Vision文字识别请求
        let request = VNRecognizeTextRequest { [weak self] (request, error) in
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
                
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    
                    recognizedText += topCandidate.string + "\n"
                    totalConfidence += topCandidate.confidence
                    observationCount += 1
                    
                    NSLog("ClipboardPlugin: Recognized text: '%@' (confidence: %.2f)", 
                          topCandidate.string, topCandidate.confidence)
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
        request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant"] // 支持英文和中文
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
}
