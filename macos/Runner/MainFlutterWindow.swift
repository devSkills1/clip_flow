import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // 设置窗口尺寸限制
    self.minSize = NSSize(width: 800, height: 600)
    self.maxSize = NSSize(width: 1920, height: 1080)
    
    // 设置窗口标题
    self.title = "ClipFlow Pro"
    
    // 允许窗口缩放
    self.styleMask.insert(.resizable)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
