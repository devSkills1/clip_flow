-- OCR功能数据库Schema变更
-- 基于现有ClipItem表结构，添加OCR相关字段和辅助表

-- 1. 扩展现有ClipItem表，添加OCR相关字段
-- 这是向后兼容的变更，不影响现有数据
ALTER TABLE clip_items ADD COLUMN ocr_text TEXT;
ALTER TABLE clip_items ADD COLUMN ocr_language VARCHAR(10) DEFAULT NULL;
ALTER TABLE clip_items ADD COLUMN ocr_confidence REAL DEFAULT NULL;
ALTER TABLE clip_items ADD COLUMN ocr_processed_at INTEGER DEFAULT NULL;
ALTER TABLE clip_items ADD COLUMN ocr_version INTEGER DEFAULT 1;
ALTER TABLE clip_items ADD COLUMN ocr_status VARCHAR(20) DEFAULT 'pending';

-- 2. 创建OCR缓存表（可选，用于高级缓存策略）
CREATE TABLE IF NOT EXISTS ocr_cache (
    id TEXT PRIMARY KEY,                    -- OCR结果ID (ocr_[image_hash]_v[version])
    source_item_id TEXT NOT NULL,           -- 源图片项目ID
    ocr_text TEXT NOT NULL,                 -- OCR识别的文本
    language VARCHAR(10),                   -- 识别语言
    confidence REAL,                        -- 置信度 0-1
    processed_at INTEGER NOT NULL,          -- 处理时间戳
    expires_at INTEGER,                     -- 过期时间
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),

    FOREIGN KEY (source_item_id) REFERENCES clip_items(id) ON DELETE CASCADE,
    INDEX idx_ocr_cache_source (source_item_id),
    INDEX idx_ocr_cache_expires (expires_at),
    INDEX idx_ocr_cache_language (language)
);

-- 3. 创建OCR处理队列表（用于持久化处理队列）
CREATE TABLE IF NOT EXISTS ocr_queue (
    id TEXT PRIMARY KEY,                    -- 队列任务ID
    item_id TEXT NOT NULL,                  -- 待处理的剪贴项ID
    priority INTEGER NOT NULL DEFAULT 0,    -- 优先级 (0=normal, 1=high, 2=urgent)
    language VARCHAR(10),                   -- 目标语言
    status VARCHAR(20) DEFAULT 'pending',   -- 状态: pending, processing, completed, failed
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    started_at INTEGER,                     -- 开始处理时间
    completed_at INTEGER,                   -- 完成时间
    error_message TEXT,                     -- 错误信息
    retry_count INTEGER DEFAULT 0,          -- 重试次数
    max_retries INTEGER DEFAULT 3,          -- 最大重试次数

    FOREIGN KEY (item_id) REFERENCES clip_items(id) ON DELETE CASCADE,
    INDEX idx_ocr_queue_status (status),
    INDEX idx_ocr_queue_priority (priority DESC),
    INDEX idx_ocr_queue_created (created_at)
);

-- 4. 创建OCR复制历史表
CREATE TABLE IF NOT EXISTS ocr_copy_history (
    id TEXT PRIMARY KEY,                    -- 记录ID
    item_id TEXT NOT NULL,                  -- 源剪贴项ID
    copy_type VARCHAR(20) NOT NULL,         -- 复制类型: image, text, both
    content_summary TEXT,                   -- 内容摘要
    success BOOLEAN NOT NULL DEFAULT TRUE,  -- 是否成功
    error_message TEXT,                     -- 错误信息
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),

    FOREIGN KEY (item_id) REFERENCES clip_items(id) ON DELETE CASCADE,
    INDEX idx_ocr_copy_item (item_id),
    INDEX idx_ocr_copy_created (created_at DESC)
);

-- 5. 创建OCR统计表（可选，用于持久化统计）
CREATE TABLE IF NOT EXISTS ocr_statistics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date DATE NOT NULL,                     -- 统计日期
    total_processed INTEGER DEFAULT 0,      -- 总处理数
    success_count INTEGER DEFAULT 0,        -- 成功数
    failure_count INTEGER DEFAULT 0,        -- 失败数
    avg_processing_time INTEGER DEFAULT 0,  -- 平均处理时间(毫秒)
    cache_hits INTEGER DEFAULT 0,           -- 缓存命中数
    cache_misses INTEGER DEFAULT 0,         -- 缓存未命中数

    UNIQUE(date),
    INDEX idx_ocr_statistics_date (date)
);

-- 6. 创建索引以优化查询性能
-- ClipItem表的OCR相关索引
CREATE INDEX IF NOT EXISTS idx_clip_items_ocr_status ON clip_items(ocr_status);
CREATE INDEX IF NOT EXISTS idx_clip_items_ocr_text ON clip_items(ocr_text);
CREATE INDEX IF NOT EXISTS idx_clip_items_ocr_processed ON clip_items(ocr_processed_at);

-- 7. 创建触发器自动更新OCR相关字段
-- 更新OCR文本时自动更新processed_at和版本号
CREATE TRIGGER IF NOT EXISTS update_ocr_timestamp
    AFTER UPDATE OF ocr_text ON clip_items
    WHEN NEW.ocr_text != OLD.ocr_text OR NEW.ocr_text IS NOT NULL
BEGIN
    UPDATE clip_items
    SET
        ocr_processed_at = strftime('%s', 'now'),
        ocr_version = OLD.ocr_version + 1,
        updated_at = strftime('%s', 'now')
    WHERE id = NEW.id;
END;

-- 8. 创建视图以简化复杂查询
-- 创建包含OCR信息的完整剪贴项视图
CREATE VIEW IF NOT EXISTS clip_items_with_ocr AS
SELECT
    ci.*,
    -- OCR状态描述
    CASE ci.ocr_status
        WHEN 'pending' THEN '等待处理'
        WHEN 'processing' THEN '正在识别'
        WHEN 'completed' THEN '已完成'
        WHEN 'failed' THEN '识别失败'
        WHEN 'skipped' THEN '已跳过'
        ELSE ci.ocr_status
    END AS ocr_status_desc,
    -- OCR文本长度（用于显示摘要）
    LENGTH(ci.ocr_text) AS ocr_text_length,
    -- OCR置信度百分比
    CASE
        WHEN ci.ocr_confidence IS NOT NULL
        THEN ROUND(ci.ocr_confidence * 100, 1)
        ELSE NULL
    END AS ocr_confidence_percent
FROM clip_items ci;

-- 9. 创建OCR清理存储过程
-- 清理过期的OCR缓存和队列记录
CREATE PROCEDURE IF NOT EXISTS cleanup_ocr_data(IN days_to_keep INTEGER)
BEGIN
    -- 清理过期的OCR缓存
    DELETE FROM ocr_cache
    WHERE expires_at IS NOT NULL
    AND expires_at < strftime('%s', 'now');

    -- 清理旧的队列记录
    DELETE FROM ocr_queue
    WHERE status IN ('completed', 'failed')
    AND completed_at < strftime('%s', 'now', '-' || days_to_keep || ' days');

    -- 清理旧的复制历史
    DELETE FROM ocr_copy_history
    WHERE created_at < strftime('%s', 'now', '-' || days_to_keep || ' days');

    -- 更新统计信息
    UPDATE ocr_statistics
    SET last_cleanup = strftime('%s', 'now')
    WHERE date = date('now');
END;

-- 10. 创建OCR性能监控视图
CREATE VIEW IF NOT EXISTS ocr_performance_metrics AS
SELECT
    date,
    total_processed,
    success_count,
    failure_count,
    CASE WHEN total_processed > 0
         THEN ROUND((success_count * 100.0 / total_processed), 2)
         ELSE 0
    END AS success_rate_percent,
    avg_processing_time,
    cache_hits,
    cache_misses,
    CASE WHEN (cache_hits + cache_misses) > 0
         THEN ROUND((cache_hits * 100.0 / (cache_hits + cache_misses)), 2)
         ELSE 0
    END AS cache_hit_rate_percent
FROM ocr_statistics
WHERE date >= date('now', '-30 days')
ORDER BY date DESC;