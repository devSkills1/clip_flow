import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
    // 手动注册 ClipboardPlugin
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      let registrar = controller.registrar(forPlugin: "ClipboardPlugin")
      ClipboardPlugin.register(with: registrar)
    }
  }
  
  private func getClipboardImage(result: @escaping FlutterResult) {
    let pasteboard = NSPasteboard.general
    
    // 检查是否有图片数据
    if let imageData = pasteboard.data(forType: .png) {
      result(FlutterStandardTypedData(bytes: imageData))
    } else if let imageData = pasteboard.data(forType: NSPasteboard.PasteboardType("public.jpeg")) {
      result(FlutterStandardTypedData(bytes: imageData))
    } else if let imageData = pasteboard.data(forType: .tiff) {
      result(FlutterStandardTypedData(bytes: imageData))
    } else {
      result(nil)
    }
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
  
  private func getSourceApp(result: @escaping FlutterResult) {
    // 获取当前活跃的应用程序
    if let frontmostApp = NSWorkspace.shared.frontmostApplication {
      result(frontmostApp.localizedName)
    } else {
      result(nil)
    }
  }
}
