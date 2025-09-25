import Cocoa
import FlutterMacOS

// 应用常量定义 (与 Flutter ClipConstants 保持一致)
struct ClipConstants {
  static let appName = "ClipFlow Pro"
  static let minWindowWidth: CGFloat = 800.0
  static let minWindowHeight: CGFloat = 600.0
  static let maxWindowWidth: CGFloat = 1920.0
  static let maxWindowHeight: CGFloat = 1080.0
}

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // 从常量获取窗口尺寸限制
    self.minSize = NSSize(width: ClipConstants.minWindowWidth, height: ClipConstants.minWindowHeight)
    self.maxSize = NSSize(width: ClipConstants.maxWindowWidth, height: ClipConstants.maxWindowHeight)
    
    // 设置窗口标题
    self.title = ClipConstants.appName
    
    // 允许窗口缩放
    self.styleMask.insert(.resizable)

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // 手动注册 ClipboardPlugin
    ClipboardPlugin.register(with: flutterViewController.registrar(forPlugin: "ClipboardPlugin"))

    super.awakeFromNib()
  }
}
