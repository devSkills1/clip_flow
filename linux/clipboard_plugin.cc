#include "clipboard_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <string>
#include <vector>
#include <memory>
#include <algorithm>
#include <cctype>
#include <fstream>
#include <sstream>

#define CLIPBOARD_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), clipboard_plugin_get_type(), \
                               ClipboardPlugin))

struct _ClipboardPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(ClipboardPlugin, clipboard_plugin, g_object_get_type())

// Forward declarations
static void clipboard_plugin_handle_method_call(
    ClipboardPlugin* self,
    FlMethodCall* method_call);

static void clipboard_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(clipboard_plugin_parent_class)->dispose(object);
}

static void clipboard_plugin_class_init(ClipboardPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = clipboard_plugin_dispose;
}

static void clipboard_plugin_init(ClipboardPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                          gpointer user_data) {
  ClipboardPlugin* plugin = CLIPBOARD_PLUGIN(user_data);
  clipboard_plugin_handle_method_call(plugin, method_call);
}

void clipboard_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  ClipboardPlugin* plugin = CLIPBOARD_PLUGIN(
      g_object_new(clipboard_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "clipboard_service",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}

// Helper functions
static std::string detect_file_type(const std::string& path) {
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

static std::string trim(const std::string& str) {
  size_t first = str.find_first_not_of(' ');
  if (std::string::npos == first) {
    return str;
  }
  size_t last = str.find_last_not_of(' ');
  return str.substr(first, (last - first + 1));
}

static bool is_color_value(const std::string& text) {
  std::string trimmed = trim(text);
  
  // 十六进制颜色检查
  if (trimmed.length() == 7 && trimmed[0] == '#') {
    for (size_t i = 1; i < trimmed.length(); i++) {
      char c = trimmed[i];
      if (!((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f'))) {
        return false;
      }
    }
    return true;
  }
  
  // RGB 格式检查
  if (trimmed.find("rgb(") == 0 || trimmed.find("rgba(") == 0) {
    return true;
  }
  
  return false;
}

static bool is_url(const std::string& text) {
  return text.find("http://") == 0 || text.find("https://") == 0 || text.find("ftp://") == 0;
}

static bool is_email(const std::string& text) {
  return text.find('@') != std::string::npos && text.find('.') != std::string::npos;
}

static bool is_file_path(const std::string& text) {
  return text.find("file://") == 0 || text.find('/') != std::string::npos;
}

static bool is_json(const std::string& text) {
  std::string trimmed = trim(text);
  return (trimmed.front() == '{' && trimmed.back() == '}') || 
         (trimmed.front() == '[' && trimmed.back() == ']');
}

static bool is_xml_or_html(const std::string& text) {
  std::string trimmed = trim(text);
  return trimmed.front() == '<' && trimmed.back() == '>';
}

static std::string detect_text_type(const std::string& text) {
  std::string trimmed = trim(text);
  
  if (is_color_value(trimmed)) {
    return "color";
  }
  
  if (is_url(trimmed)) {
    return "url";
  }
  
  if (is_email(trimmed)) {
    return "email";
  }
  
  if (is_file_path(trimmed)) {
    return "path";
  }
  
  if (is_json(trimmed)) {
    return "json";
  }
  
  if (is_xml_or_html(trimmed)) {
    return "markup";
  }
  
  return "plain";
}

static void get_clipboard_type(FlMethodCall* method_call) {
  GtkClipboard* clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  
  g_autoptr(FlValue) result_map = fl_value_new_map();
  
  // 优先检查 RTF 格式 (最高优先级)
  if (gtk_clipboard_wait_is_target_available(clipboard, gdk_atom_intern("text/rtf", FALSE))) {
    fl_value_set_string_take(result_map, "type", fl_value_new_string("text"));
    fl_value_set_string_take(result_map, "subType", fl_value_new_string("rtf"));
    fl_value_set_string_take(result_map, "hasData", fl_value_new_bool(TRUE));
    fl_value_set_string_take(result_map, "priority", fl_value_new_int(1));
  }
  // 检查 HTML 格式 (第二优先级)
  else if (gtk_clipboard_wait_is_target_available(clipboard, gdk_atom_intern("text/html", FALSE))) {
    fl_value_set_string_take(result_map, "type", fl_value_new_string("text"));
    fl_value_set_string_take(result_map, "subType", fl_value_new_string("html"));
    fl_value_set_string_take(result_map, "hasData", fl_value_new_bool(TRUE));
    fl_value_set_string_take(result_map, "priority", fl_value_new_int(2));
  }
  // 检查文件类型 (第三优先级) (text/uri-list)
  else if (gtk_clipboard_wait_is_target_available(clipboard, gdk_atom_intern("text/uri-list", FALSE))) {
    gchar* uris_text = gtk_clipboard_wait_for_text(clipboard);
    if (uris_text != nullptr) {
      std::string uris_str(uris_text);
      std::istringstream iss(uris_str);
      std::string line;
      std::vector<std::string> file_paths;
      
      while (std::getline(iss, line)) {
        if (!line.empty() && line.find("file://") == 0) {
          std::string path = line.substr(7); // Remove "file://"
          file_paths.push_back(path);
        }
      }
      
      if (!file_paths.empty()) {
        std::string first_path = file_paths[0];
        std::string file_type = detect_file_type(first_path);
        
        g_autoptr(FlValue) paths_list = fl_value_new_list();
        for (const auto& path : file_paths) {
          fl_value_append_take(paths_list, fl_value_new_string(path.c_str()));
        }
        
        fl_value_set_string_take(result_map, "type", fl_value_new_string("file"));
        fl_value_set_string_take(result_map, "subType", fl_value_new_string(file_type.c_str()));
        fl_value_set_string_take(result_map, "content", paths_list);
        fl_value_set_string_take(result_map, "primaryPath", fl_value_new_string(first_path.c_str()));
        fl_value_set_string_take(result_map, "priority", fl_value_new_int(3));
      }
      
      g_free(uris_text);
    }
  }
  // 检查图片类型 (第四优先级)
  else if (gtk_clipboard_wait_is_image_available(clipboard)) {
    GdkPixbuf* pixbuf = gtk_clipboard_wait_for_image(clipboard);
    if (pixbuf != nullptr) {
      fl_value_set_string_take(result_map, "type", fl_value_new_string("image"));
      fl_value_set_string_take(result_map, "subType", fl_value_new_string("pixbuf"));
      fl_value_set_string_take(result_map, "hasData", fl_value_new_bool(TRUE));
      fl_value_set_string_take(result_map, "priority", fl_value_new_int(4));
      
      g_object_unref(pixbuf);
    }
  }
  // 检查文本类型 (最低优先级)
  else if (gtk_clipboard_wait_is_text_available(clipboard)) {
    gchar* text = gtk_clipboard_wait_for_text(clipboard);
    if (text != nullptr) {
      std::string text_str(text);
      std::string text_type = detect_text_type(text_str);
      
      fl_value_set_string_take(result_map, "type", fl_value_new_string("text"));
      fl_value_set_string_take(result_map, "subType", fl_value_new_string(text_type.c_str()));
      fl_value_set_string_take(result_map, "content", fl_value_new_string(text));
      fl_value_set_string_take(result_map, "length", fl_value_new_int(text_str.length()));
      fl_value_set_string_take(result_map, "priority", fl_value_new_int(5));
      
      g_free(text);
    }
  }
  else {
    // 未知类型
    fl_value_set_string_take(result_map, "type", fl_value_new_string("unknown"));
    fl_value_set_string_take(result_map, "priority", fl_value_new_int(99));
  }
  
  fl_method_call_respond_success(method_call, result_map, nullptr);
}

static void get_clipboard_sequence(FlMethodCall* method_call) {
  // Linux 没有直接的序列号概念，使用时间戳作为替代
  static gint64 last_sequence = 0;
  last_sequence++;
  
  g_autoptr(FlValue) result = fl_value_new_int(last_sequence);
  fl_method_call_respond_success(method_call, result, nullptr);
}

static void get_clipboard_file_paths(FlMethodCall* method_call) {
  GtkClipboard* clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  
  if (gtk_clipboard_wait_is_target_available(clipboard, gdk_atom_intern("text/uri-list", FALSE))) {
    gchar* uris_text = gtk_clipboard_wait_for_text(clipboard);
    if (uris_text != nullptr) {
      std::string uris_str(uris_text);
      std::istringstream iss(uris_str);
      std::string line;
      
      g_autoptr(FlValue) paths_list = fl_value_new_list();
      
      while (std::getline(iss, line)) {
        if (!line.empty() && line.find("file://") == 0) {
          std::string path = line.substr(7); // Remove "file://"
          fl_value_append_take(paths_list, fl_value_new_string(path.c_str()));
        }
      }
      
      fl_method_call_respond_success(method_call, paths_list, nullptr);
      g_free(uris_text);
      return;
    }
  }
  
  fl_method_call_respond_success(method_call, nullptr, nullptr);
}

static void get_clipboard_image_data(FlMethodCall* method_call) {
  GtkClipboard* clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  
  if (gtk_clipboard_wait_is_image_available(clipboard)) {
    GdkPixbuf* pixbuf = gtk_clipboard_wait_for_image(clipboard);
    if (pixbuf != nullptr) {
      gchar* buffer;
      gsize buffer_size;
      GError* error = nullptr;
      
      if (gdk_pixbuf_save_to_buffer(pixbuf, &buffer, &buffer_size, "png", &error, nullptr)) {
        g_autoptr(FlValue) result = fl_value_new_uint8_list(
            reinterpret_cast<const uint8_t*>(buffer), buffer_size);
        fl_method_call_respond_success(method_call, result, nullptr);
        g_free(buffer);
      } else {
        fl_method_call_respond_error(method_call, "IMAGE_ERROR", 
                                   error ? error->message : "Failed to save image", 
                                   nullptr, nullptr);
        if (error) g_error_free(error);
      }
      
      g_object_unref(pixbuf);
      return;
    }
  }
  
  fl_method_call_respond_success(method_call, nullptr, nullptr);
}

static void clipboard_plugin_handle_method_call(
    ClipboardPlugin* self,
    FlMethodCall* method_call) {
  
  const gchar* method = fl_method_call_get_name(method_call);
  
  if (strcmp(method, "getClipboardType") == 0) {
    get_clipboard_type(method_call);
  } else if (strcmp(method, "getClipboardSequence") == 0) {
    get_clipboard_sequence(method_call);
  } else if (strcmp(method, "getClipboardFilePaths") == 0) {
    get_clipboard_file_paths(method_call);
  } else if (strcmp(method, "getClipboardImageData") == 0) {
    get_clipboard_image_data(method_call);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}