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
  private var isSetup = false

  override func awakeFromNib() {
    super.awakeFromNib()
    setupWindow()
  }

  private func setupWindow() {
    guard !isSetup else { return }

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    configureWindow()
    setupFlutterPlugins(flutterViewController)

    isSetup = true
  }

  private func configureWindow() {
    // 窗口基本属性
    self.title = ClipConstants.appName
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.isMovable = true
    self.isMovableByWindowBackground = true

    // 尺寸和缩放
    self.minSize = NSSize(width: ClipConstants.minWindowWidth, height: ClipConstants.minWindowHeight)
    self.maxSize = NSSize(width: ClipConstants.maxWindowWidth, height: ClipConstants.maxWindowHeight)

    // 窗口样式
    self.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
    hideSystemWindowButtons()

    // 窗口层级和外观
    self.level = .normal
    self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

    // 设置阴影
    self.hasShadow = true

    // 设置背景色
    self.backgroundColor = NSColor.windowBackgroundColor

    // 启用自动保存窗口位置
    self.setFrameAutosaveName("MainWindow")

    // 隐藏全屏按钮（仅在支持的macOS版本）
    if #available(macOS 10.12, *) {
      self.collectionBehavior.insert(.fullScreenNone)
    }

    print("✅ macOS window configuration completed")
  }

  private func setupFlutterPlugins(_ flutterViewController: FlutterViewController) {
    RegisterGeneratedPlugins(registry: flutterViewController)

    // 手动注册 ClipboardPlugin
    ClipboardPlugin.register(with: flutterViewController.registrar(forPlugin: "ClipboardPlugin"))

    print("✅ Flutter plugins registered successfully")
  }

  private func hideSystemWindowButtons() {
    self.standardWindowButton(.closeButton)?.isHidden = true
    self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    self.standardWindowButton(.zoomButton)?.isHidden = true

    if #available(macOS 11.0, *) {
      self.toolbarStyle = .unifiedCompact
    }
  }

  // MARK: - 窗口配置

  // 启用响应
  override var acceptsFirstResponder: Bool {
    return true
  }

  // MARK: - 窗口尺寸限制

  override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
    var newRect = super.constrainFrameRect(frameRect, to: screen)

    // 确保窗口大小在限制范围内
    let minSize = self.minSize
    let maxSize = self.maxSize

    if newRect.size.width < minSize.width {
      newRect.size.width = minSize.width
    }
    if newRect.size.height < minSize.height {
      newRect.size.height = minSize.height
    }
    if newRect.size.width > maxSize.width {
      newRect.size.width = maxSize.width
    }
    if newRect.size.height > maxSize.height {
      newRect.size.height = maxSize.height
    }

    return newRect
  }

  // MARK: - 自定义窗口动画

  func animateResize(to newFrame: NSRect) {
    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.2
      context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      self.animator().setFrame(newFrame, display: true)
    }
  }
}
