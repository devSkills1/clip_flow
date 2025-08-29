import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // 从 Flutter 常量获取窗口尺寸限制
    // 这些值与 ClipConstants 中定义的值保持一致
    self.minSize = NSSize(width: ClipConstants.minWindowWidth, height: ClipConstants.minWindowHeight)  // ClipConstants.minWindowWidth/Height
    self.maxSize = NSSize(width: ClipConstants.maxWindowWidth, height: ClipConstants.maxWindowHeight)  // ClipConstants.maxWindowWidth/Height
    
    // 设置窗口标题 (与 ClipConstants.appName 保持一致)
    self.title = ClipConstants.appName
    
    // 允许窗口缩放
    self.styleMask.insert(.resizable)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
