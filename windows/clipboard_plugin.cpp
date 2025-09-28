#include "clipboard_plugin.h"
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <shlobj.h>
#include <string>
#include <vector>
#include <memory>
#include <algorithm>
#include <cctype>

namespace clipboard_plugin {

// static
void ClipboardPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "clipboard_service",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<ClipboardPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

ClipboardPlugin::ClipboardPlugin() {}

ClipboardPlugin::~ClipboardPlugin() {}

void ClipboardPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (method_call.method_name().compare("getClipboardType") == 0) {
    GetClipboardType(std::move(result));
  } else if (method_call.method_name().compare("getClipboardSequence") == 0) {
    GetClipboardSequence(std::move(result));
  } else if (method_call.method_name().compare("getClipboardFilePaths") == 0) {
    GetClipboardFilePaths(std::move(result));
  } else if (method_call.method_name().compare("getClipboardImageData") == 0) {
    GetClipboardImageData(std::move(result));
  } else {
    result->NotImplemented();
  }
}

void ClipboardPlugin::GetClipboardType(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (!OpenClipboard(nullptr)) {
    result->Error("CLIPBOARD_ERROR", "Failed to open clipboard");
    return;
  }

  flutter::EncodableMap clipboard_info;
  
  // 优先检查 RTF 格式 (最高优先级)
  if (IsClipboardFormatAvailable(RegisterClipboardFormatW(L"Rich Text Format"))) {
    clipboard_info[flutter::EncodableValue("type")] = flutter::EncodableValue("text");
    clipboard_info[flutter::EncodableValue("subType")] = flutter::EncodableValue("rtf");
    clipboard_info[flutter::EncodableValue("hasData")] = flutter::EncodableValue(true);
    clipboard_info[flutter::EncodableValue("priority")] = flutter::EncodableValue(1);
  }
  // 检查 HTML 格式 (第二优先级)
  else if (IsClipboardFormatAvailable(RegisterClipboardFormatW(L"HTML Format"))) {
    clipboard_info[flutter::EncodableValue("type")] = flutter::EncodableValue("text");
    clipboard_info[flutter::EncodableValue("subType")] = flutter::EncodableValue("html");
    clipboard_info[flutter::EncodableValue("hasData")] = flutter::EncodableValue(true);
    clipboard_info[flutter::EncodableValue("priority")] = flutter::EncodableValue(2);
  }
  // 检查文件类型 (第三优先级)
  else if (IsClipboardFormatAvailable(CF_HDROP)) {
    HANDLE hData = GetClipboardData(CF_HDROP);
    if (hData != nullptr) {
      HDROP hDrop = static_cast<HDROP>(hData);
      UINT fileCount = DragQueryFileW(hDrop, 0xFFFFFFFF, nullptr, 0);
      
      if (fileCount > 0) {
        std::vector<flutter::EncodableValue> file_paths;
        wchar_t filePath[MAX_PATH];
        
        for (UINT i = 0; i < fileCount; i++) {
          if (DragQueryFileW(hDrop, i, filePath, MAX_PATH)) {
            std::wstring ws(filePath);
            std::string path(ws.begin(), ws.end());
            file_paths.push_back(flutter::EncodableValue(path));
          }
        }
        
        if (!file_paths.empty()) {
          std::string first_path = std::get<std::string>(file_paths[0]);
          std::string file_type = DetectFileType(first_path);
          
          clipboard_info[flutter::EncodableValue("type")] = flutter::EncodableValue("file");
          clipboard_info[flutter::EncodableValue("subType")] = flutter::EncodableValue(file_type);
          clipboard_info[flutter::EncodableValue("content")] = flutter::EncodableValue(file_paths);
          clipboard_info[flutter::EncodableValue("primaryPath")] = flutter::EncodableValue(first_path);
          clipboard_info[flutter::EncodableValue("priority")] = flutter::EncodableValue(3);
        }
      }
    }
  }
  // 检查图片类型 (第四优先级)
  else if (IsClipboardFormatAvailable(CF_DIB) || IsClipboardFormatAvailable(CF_BITMAP)) {
    std::string image_format = "bitmap";
    if (IsClipboardFormatAvailable(CF_DIB)) {
      image_format = "dib";
    }
    
    clipboard_info[flutter::EncodableValue("type")] = flutter::EncodableValue("image");
    clipboard_info[flutter::EncodableValue("subType")] = flutter::EncodableValue(image_format);
    clipboard_info[flutter::EncodableValue("hasData")] = flutter::EncodableValue(true);
    clipboard_info[flutter::EncodableValue("priority")] = flutter::EncodableValue(4);
  }
  // 检查文本类型 (最低优先级)
  else if (IsClipboardFormatAvailable(CF_UNICODETEXT) || IsClipboardFormatAvailable(CF_TEXT)) {
    HANDLE hData = GetClipboardData(CF_UNICODETEXT);
    if (hData != nullptr) {
      wchar_t* pszText = static_cast<wchar_t*>(GlobalLock(hData));
      if (pszText != nullptr) {
        std::wstring ws(pszText);
        std::string text(ws.begin(), ws.end());
        std::string text_type = DetectTextType(text);
        
        clipboard_info[flutter::EncodableValue("type")] = flutter::EncodableValue("text");
        clipboard_info[flutter::EncodableValue("subType")] = flutter::EncodableValue(text_type);
        clipboard_info[flutter::EncodableValue("content")] = flutter::EncodableValue(text);
        clipboard_info[flutter::EncodableValue("length")] = flutter::EncodableValue(static_cast<int>(text.length()));
        clipboard_info[flutter::EncodableValue("priority")] = flutter::EncodableValue(5);
        
        GlobalUnlock(hData);
      }
    }
  }
  else {
    // 未知类型
    clipboard_info[flutter::EncodableValue("type")] = flutter::EncodableValue("unknown");
    clipboard_info[flutter::EncodableValue("priority")] = flutter::EncodableValue(99);
  }

  CloseClipboard();
  result->Success(flutter::EncodableValue(clipboard_info));
}

void ClipboardPlugin::GetClipboardSequence(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  DWORD sequence = GetClipboardSequenceNumber();
  result->Success(flutter::EncodableValue(static_cast<int64_t>(sequence)));
}

void ClipboardPlugin::GetClipboardFilePaths(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (!OpenClipboard(nullptr)) {
    result->Success(flutter::EncodableValue());
    return;
  }

  std::vector<flutter::EncodableValue> file_paths;
  
  if (IsClipboardFormatAvailable(CF_HDROP)) {
    HANDLE hData = GetClipboardData(CF_HDROP);
    if (hData != nullptr) {
      HDROP hDrop = static_cast<HDROP>(hData);
      UINT fileCount = DragQueryFileW(hDrop, 0xFFFFFFFF, nullptr, 0);
      
      wchar_t filePath[MAX_PATH];
      for (UINT i = 0; i < fileCount; i++) {
        if (DragQueryFileW(hDrop, i, filePath, MAX_PATH)) {
          std::wstring ws(filePath);
          std::string path(ws.begin(), ws.end());
          file_paths.push_back(flutter::EncodableValue(path));
        }
      }
    }
  }

  CloseClipboard();
  
  if (file_paths.empty()) {
    result->Success(flutter::EncodableValue());
  } else {
    result->Success(flutter::EncodableValue(file_paths));
  }
}

void ClipboardPlugin::GetClipboardImageData(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (!OpenClipboard(nullptr)) {
    result->Success(flutter::EncodableValue());
    return;
  }

  std::vector<uint8_t> image_data;
  
  if (IsClipboardFormatAvailable(CF_DIB)) {
    HANDLE hData = GetClipboardData(CF_DIB);
    if (hData != nullptr) {
      BITMAPINFO* pBitmapInfo = static_cast<BITMAPINFO*>(GlobalLock(hData));
      if (pBitmapInfo != nullptr) {
        SIZE_T dataSize = GlobalSize(hData);
        image_data.resize(dataSize);
        memcpy(image_data.data(), pBitmapInfo, dataSize);
        GlobalUnlock(hData);
      }
    }
  }

  CloseClipboard();
  
  if (image_data.empty()) {
    result->Success(flutter::EncodableValue());
  } else {
    result->Success(flutter::EncodableValue(image_data));
  }
}

std::string ClipboardPlugin::DetectFileType(const std::string& path) {
  // 获取文件扩展名
  size_t dot_pos = path.find_last_of('.');
  if (dot_pos == std::string::npos) {
    return "file";
  }
  
  std::string extension = path.substr(dot_pos + 1);
  std::transform(extension.begin(), extension.end(), extension.begin(), ::tolower);
  
  // 图片文件
  std::vector<std::string> image_extensions = {
    "png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "tif", "svg", "ico", "heic", "heif"
  };
  if (std::find(image_extensions.begin(), image_extensions.end(), extension) != image_extensions.end()) {
    return "image";
  }
  
  // 音频文件
  std::vector<std::string> audio_extensions = {
    "mp3", "wav", "aac", "flac", "ogg", "m4a", "wma", "aiff", "au"
  };
  if (std::find(audio_extensions.begin(), audio_extensions.end(), extension) != audio_extensions.end()) {
    return "audio";
  }
  
  // 视频文件
  std::vector<std::string> video_extensions = {
    "mp4", "avi", "mov", "wmv", "flv", "webm", "mkv", "m4v", "3gp", "ts"
  };
  if (std::find(video_extensions.begin(), video_extensions.end(), extension) != video_extensions.end()) {
    return "video";
  }
  
  // 文档文件
  std::vector<std::string> document_extensions = {
    "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf"
  };
  if (std::find(document_extensions.begin(), document_extensions.end(), extension) != document_extensions.end()) {
    return "document";
  }
  
  // 压缩文件
  std::vector<std::string> archive_extensions = {
    "zip", "rar", "7z", "tar", "gz", "bz2", "xz"
  };
  if (std::find(archive_extensions.begin(), archive_extensions.end(), extension) != archive_extensions.end()) {
    return "archive";
  }
  
  // 代码文件
  std::vector<std::string> code_extensions = {
    "cpp", "c", "h", "cs", "js", "ts", "py", "java", "go", "rs", "php", "rb", "kt", "dart"
  };
  if (std::find(code_extensions.begin(), code_extensions.end(), extension) != code_extensions.end()) {
    return "code";
  }
  
  return "file";
}

std::string ClipboardPlugin::DetectTextType(const std::string& text) {
  std::string trimmed = text;
  // 简单的 trim 实现
  trimmed.erase(trimmed.begin(), std::find_if(trimmed.begin(), trimmed.end(), [](unsigned char ch) {
    return !std::isspace(ch);
  }));
  trimmed.erase(std::find_if(trimmed.rbegin(), trimmed.rend(), [](unsigned char ch) {
    return !std::isspace(ch);
  }).base(), trimmed.end());
  
  // 检查是否是颜色值
  if (IsColorValue(trimmed)) {
    return "color";
  }
  
  // 检查是否是 URL
  if (IsURL(trimmed)) {
    return "url";
  }
  
  // 检查是否是邮箱
  if (IsEmail(trimmed)) {
    return "email";
  }
  
  // 检查是否是文件路径
  if (IsFilePath(trimmed)) {
    return "path";
  }
  
  // 检查是否是 JSON
  if (IsJSON(trimmed)) {
    return "json";
  }
  
  // 检查是否是 XML/HTML
  if (IsXMLOrHTML(trimmed)) {
    return "markup";
  }
  
  return "plain";
}

bool ClipboardPlugin::IsColorValue(const std::string& text) {
  // 简单的十六进制颜色检查
  if (text.length() == 7 && text[0] == '#') {
    for (size_t i = 1; i < text.length(); i++) {
      char c = text[i];
      if (!((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f'))) {
        return false;
      }
    }
    return true;
  }
  
  // RGB 格式检查
  if (text.find("rgb(") == 0 || text.find("rgba(") == 0) {
    return true;
  }
  
  return false;
}

bool ClipboardPlugin::IsURL(const std::string& text) {
  return text.find("http://") == 0 || text.find("https://") == 0 || text.find("ftp://") == 0;
}

bool ClipboardPlugin::IsEmail(const std::string& text) {
  return text.find('@') != std::string::npos && text.find('.') != std::string::npos;
}

bool ClipboardPlugin::IsFilePath(const std::string& text) {
  return text.find("file://") == 0 || text.find('/') != std::string::npos || text.find('\\') != std::string::npos;
}

bool ClipboardPlugin::IsJSON(const std::string& text) {
  return (text.front() == '{' && text.back() == '}') || (text.front() == '[' && text.back() == ']');
}

bool ClipboardPlugin::IsXMLOrHTML(const std::string& text) {
  return text.front() == '<' && text.back() == '>';
}

}  // namespace clipboard_plugin