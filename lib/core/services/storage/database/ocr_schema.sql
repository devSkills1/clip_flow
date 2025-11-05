-- OCR功能数据库Schema设计
-- 基于单表设计方案的ClipItem表OCR字段定义
-- 日期: 2025-01-05
-- 版本: 2.0

-- ClipItem表的OCR相关字段定义
-- 单表设计：图片和OCR文本存储在同一个记录中
-- ocr_text_id 用于OCR文本复制时的去重和状态管理

-- 1. ClipItem表OCR字段 (已在现有表结构中实现)
-- 这些字段通过DatabaseService._onUpgrade()方法自动添加
-- ALTER TABLE clip_items ADD COLUMN ocr_text TEXT;
-- ALTER TABLE clip_items ADD COLUMN ocr_text_id TEXT;
-- ALTER TABLE clip_items ADD COLUMN is_ocr_extracted INTEGER NOT NULL DEFAULT 0;

-- 2. ClipItem表OCR相关索引 (已在现有代码中实现)
-- 这些索引在DatabaseService._onCreate()中创建
-- CREATE INDEX idx_clip_items_ocr_text_id ON clip_items(ocr_text_id);
-- CREATE INDEX idx_clip_items_is_ocr_extracted ON clip_items(is_ocr_extracted);

-- 3. OCR数据处理流程说明
--
-- 图片复制流程：
-- clip_items (type=image, ocr_text=null, ocr_text_id=null, is_ocr_extracted=0)
--     ↓ (ClipboardProcessor._processImageData())
-- OCR识别 → 生成ocr_text_id
--     ↓
-- clip_items (type=image, ocr_text="识别文本", ocr_text_id="generated_id", is_ocr_extracted=1)
--
-- OCR复制流程：
-- 点击OCR → 使用ocr_text_id更新记录时间戳
--     ↓
-- 剪贴板监控检测到相同ocr_text_id → 更新而非创建新记录
--
-- 4. OCR字段说明
-- ocr_text: TEXT
--   - OCR识别的文本内容
--   - 用于显示和搜索
--   - 支持多语言文本
--
-- ocr_text_id: TEXT
--   - OCR文本的唯一标识符
--   - 使用IdGenerator.generateOcrTextId()生成
--   - 格式: ocr_text:[parent_image_id]:[normalized_text_hash]
--   - 用于OCR复制时的去重机制
--
-- is_ocr_extracted: INTEGER (0/1)
--   - 标记是否已进行OCR识别
--   - 0: 未识别或识别失败
--   - 1: 已成功识别

-- 5. ID生成策略
--
-- 图片记录ID:
-- IdGenerator.generateId(
--   ClipType.image,
--   content,
--   filePath,
--   metadata,
//   → "image:normalized_filename"
//
-- OCR文本ID (当OCR文本存在时):
// IdGenerator.generateOcrTextId(
//   ocrText,
//   parentImageId,
// ) → "ocr_text:image_id:normalized_text_hash"
//
// 注意：OCR文本记录实际上存储在图片记录中，不创建独立记录

-- 6. 复制操作流程
--
-- 图片复制:
// _onItemTap() → clipboardServiceProvider.setClipboardContent(item)
// → 剪贴板监控 → 使用图片ID → 更新图片记录时间戳
//
// OCR文本复制:
// _onOcrTextTap() → Clipboard.setData(ocrText)
// → 剪贴板监控 → 使用ocr_text_id → 更新对应记录时间戳
// → 不会创建新记录，避免重复

-- 7. 数据完整性保证
--
-- 去重机制:
// - DeduplicationService.checkAndPrepare() 确保相同内容不重复
// - OCR文本复制时通过ocr_text_id避免创建重复记录
//
// 数据关联:
// - ocr_text_id 建于图片ID和文本内容生成
// - 同一张图片的OCR文本始终有相同的ocr_text_id
// - 不同图片的相同OCR文本会有不同的ocr_text_id

-- 8. 版本兼容性
--
-- Version 1.0 → 2.0 变更:
// - 移除 parent_image_id (单表设计不需要)
// - 移除 origin_width/origin_height (使用metadata替代)
// - 移除 schema_version (硬编码字段)
// - 保留 ocr_text, ocr_text_id, is_ocr_extracted 核心字段
//
// 数据库升级:
// DatabaseService._onUpgrade(oldVersion: 1, newVersion: 2)
// - 自动清理废弃字段
// - 确保核心OCR字段存在
// - 重建必要索引

-- 9. 查询示例
--
-- 查询包含OCR文本的图片:
-- SELECT id, type, content, ocr_text, ocr_text_id, is_ocr_extracted
-- FROM clip_items
-- WHERE type = 'image' AND is_ocr_extracted = 1;
//
-- 查询特定图片的OCR文本:
-- SELECT ocr_text
-- FROM clip_items
-- WHERE id = 'image_id' AND is_ocr_extracted = 1;
//
-- 按OCR文本长度排序:
-- SELECT id, LENGTH(ocr_text) as text_length, ocr_text
-- FROM clip_items
-- WHERE type = 'image' AND is_ocr_extracted = 1
-- ORDER BY text_length DESC;

-- 10. 性能优化建议
--
-- 索引使用:
-- - ocr_text_id: 用于OCR复制时的快速查找
// - is_ocr_extracted: 用于筛选已识别的图片
//
// 查询优化:
// - 使用LIMIT限制结果数量
// - 对大量OCR文本使用分页
// - 定期清理过期数据

-- 11. 未来扩展性
--
// 当前单表设计已满足OCR功能需求，如需扩展可考虑:
// - 添加ocr_confidence字段存储置信度
// - 添加ocr_language字段存储识别语言
// - 添加ocr_version字段跟踪处理版本
// - 创建OCR历史记录表（如需要）
//
// 所有扩展都应保持单表设计的一致性。