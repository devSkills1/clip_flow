# iCloud 同步实现指南

本文聚焦于 ClipFlow Pro 现有的 Flutter + macOS iCloud 同步方案，帮助贡献者完成配置、排查与扩展。目标平台为 macOS（CloudKit），Windows/Linux 仍使用本地数据库。

## 架构概览

- **Flutter 层**：`lib/core/services/sync/icloud_sync_service.dart` 定义 `ICloudSyncService`，通过 `MethodChannel('icloud_sync')` 调用原生能力，并在 `ClipRepositoryImpl` 与 `main.dart` 中触发上传/拉取。
- **本地存储**：`DatabaseService` 仍是权威数据源，iCloud 仅同步其内容，所有冲突由 “更新更晚覆盖更早” 策略解决。
- **macOS 原生插件**：`macos/Runner/ICloudSyncPlugin.swift` 直接使用 CloudKit。Flutter 侧调用 `initialize`、`upsertClip`、`deleteClip`、`fetchClips`，插件负责字段序列化及错误上报。

## 前置条件与配置

1. **CloudKit 容器**：在 Apple Developer 控制台创建容器（示例 `iCloud.com.example.clipflowpro`）。把容器 ID 写入 `ClipConstants.icloudContainerId`，并在 `macos/Runner/DebugProfile.entitlements` 与 `Release.entitlements` 的 `com.apple.developer.icloud-container-identifiers` 中保持一致。
2. **Xcode 能力**：在 Runner target → Signing & Capabilities 中开启 “iCloud → CloudKit”，勾选容器；保持 App Sandbox 打开以允许本地数据库与网络访问。
3. **Apple ID 登录**：目标 Mac 必须在系统设置中登录 Apple ID 且开启 iCloud Drive，否则 CloudKit 请求会返回 `CKError.notAuthenticated`。
4. **依赖安装**：执行 `flutter pub get`，必要时运行 `pod install` 以确保 Swift 插件编译。

## Flutter 层细节

1. **服务初始化**：`_initializeICloudSyncIfNeeded()` 在 `main.dart` 中于数据库就绪后执行，传入 `ICloudSyncConfig`（容器、记录类型、订阅 ID、数据库 scope）。该方法：
   - 调用 `ICloudSyncService.configure` 初始化 MethodChannel。
   - 将 `DatabaseService.getAllClipItems()` 结果上传。
   - 调用 `fetchRemoteClips()` 并与本地按 `updatedAt` 合并。
2. **仓库钩子**：`ClipRepositoryImpl` 在 `save`、`delete`、`updateFavoriteStatus` 完成本地操作后，使用 `unawaited` 将同步任务排入后台，避免阻塞 UI。
3. **常量位置**：所有 iCloud 相关常量集中在 `ClipConstants`，方便构建脚本注入。

## macOS 插件接口

`ICloudSyncPlugin` 注册于 `AppDelegate`，并加入 Xcode 工程 `Sources`。核心方法：

- `initialize`：基于容器 ID、scope 选择 `CKDatabase`，失败会返回 `FlutterError(no_database)`。
- `upsertClip`：读取 `record` 字段，补齐 `CKRecord`，并保存至 CloudKit；支持空字段清空逻辑与 thumbnail/metadata JSON 序列化。
- `deleteClip`：根据 recordName 删除 CloudKit 记录。
- `fetchClips`：可选 `since` 参数（ISO8601），按 `updatedAt` 过滤，返回 Dart 可解析的 `Map<String,dynamic>` 列表。

插件遵循主线程回调，所有错误通过 `FlutterError` 返回到 Dart 侧以便日志记录 (`Log.w`)。

## 同步流程

1. 应用启动 → 数据库初始化 → 调用 `_initializeICloudSyncIfNeeded()`。
2. `ICloudSyncService.configure()` 成功后，上传本地最新记录，再拉取远端记录到 SQLite。
3. 用户新增/删除/收藏 → `ClipRepositoryImpl` 更新数据库 → 触发对应的 `upsertClip` 或 `deleteClip`。
4. 后续可扩展 CloudKit Subscription，以推送远端变更；当前版本通过手动拉取完成合并。

## 验证步骤

1. **格式/静态检查**：在本地终端运行 `dart format lib test` 与 `flutter analyze`，确保新增文件通过格式与分析。
2. **构建运行**：执行 `flutter run -d macos` 或在 Xcode 里直接 Run，使用与容器匹配的签名团队。
3. **功能测试**：
   - 登录相同 Apple ID 的两台 Mac，均安装 ClipFlow Pro。
   - 在 A 机复制多条文本，确认默认列表出现后，等待 1-2 分钟或手动触发“刷新”按钮（若实现）。
   - 在 B 机启动应用，验证历史记录已同步；再在 B 机删除/收藏，观察 A 机是否更新。
4. **日志诊断**：出现同步失败时查看 `~/Library/Logs/ClipFlow Pro/` 内日志，常见错误包括容器 ID 不匹配、iCloud 未登录、权限缺失等。

## 常见问题与建议

- **未登录 iCloud**：Flutter 侧日志会打印 `CKError.notAuthenticated`，提示用户先在系统设置中登录 Apple ID。
- **容器 ID 不一致**：若 Dart 常量与 entitlements、Xcode 能力不匹配，CloudKit 返回 `CKError.permissionFailure`。
- **大量数据初次上传**：`_pushLocalItemsToICloud` 会逐条调用 `upsertClip`，必要时可改为批处理或分批上传。
- **扩展方向**：可在 `ICloudSyncPlugin` 中添加订阅创建、冲突策略或 Asset 存储，以支持大图片/附件同步。

完成上述配置后，即可在 macOS 端体验 ClipFlow Pro 的 iCloud 同步。若需跨平台统一云端存储，请在服务层新增其它同步实现并通过依赖注入切换。
