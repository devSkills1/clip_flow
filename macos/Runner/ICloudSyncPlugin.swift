import CloudKit
import FlutterMacOS

class ICloudSyncPlugin: NSObject, FlutterPlugin {
  private var container: CKContainer?
  private var database: CKDatabase?
  private var recordType: String = "ClipItem"
  private var subscriptionId: String = "clipflow_sync_subscription"
  private let isoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "icloud_sync", binaryMessenger: registrar.messenger)
    let instance = ICloudSyncPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      handleInitialize(call: call, result: result)
    case "upsertClip":
      handleUpsert(call: call, result: result)
    case "deleteClip":
      handleDelete(call: call, result: result)
    case "fetchClips":
      handleFetch(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleInitialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let containerId = args["containerId"] as? String,
          !containerId.isEmpty else {
      result(FlutterError(code: "invalid_args", message: "Missing containerId", details: nil))
      return
    }

    recordType = (args["recordType"] as? String) ?? recordType
    subscriptionId = (args["subscriptionId"] as? String) ?? subscriptionId
    let scope = (args["databaseScope"] as? String)?.lowercased() ?? "private"

    container = CKContainer(identifier: containerId)
    switch scope {
    case "public":
      database = container?.publicCloudDatabase
    case "shared":
      database = container?.sharedCloudDatabase
    default:
      database = container?.privateCloudDatabase
    }

    guard database != nil else {
      result(FlutterError(code: "no_database", message: "Cannot access iCloud database", details: nil))
      return
    }

    result(true)
  }

  private func handleUpsert(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let database else {
      result(FlutterError(code: "not_initialized", message: "iCloud sync is not configured", details: nil))
      return
    }

    guard let args = call.arguments as? [String: Any],
          let recordData = args["record"] as? [String: Any],
          let recordId = recordData["id"] as? String else {
      result(FlutterError(code: "invalid_args", message: "Missing clip payload", details: nil))
      return
    }

    let ckRecordID = CKRecord.ID(recordName: recordId)
    database.fetch(withRecordID: ckRecordID) { existingRecord, error in
      if let ckError = error as? CKError, ckError.code == .unknownItem {
        let freshRecord = CKRecord(recordType: self.recordType, recordID: ckRecordID)
        self.apply(recordData, to: freshRecord)
        self.save(record: freshRecord, result: result)
        return
      }

      if let error = error {
        self.finishWithError(code: "fetch_failed", message: "Unable to fetch clip", error: error, result: result)
        return
      }

      let record = existingRecord ?? CKRecord(recordType: self.recordType, recordID: ckRecordID)
      self.apply(recordData, to: record)
      self.save(record: record, result: result)
    }
  }

  private func handleDelete(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let database else {
      result(FlutterError(code: "not_initialized", message: "iCloud sync is not configured", details: nil))
      return
    }

    guard let args = call.arguments as? [String: Any],
          let recordId = args["id"] as? String else {
      result(FlutterError(code: "invalid_args", message: "Missing record id", details: nil))
      return
    }

    let ckRecordID = CKRecord.ID(recordName: recordId)
    database.delete(withRecordID: ckRecordID) { _, error in
      if let error = error {
        self.finishWithError(code: "delete_failed", message: "Unable to delete clip", error: error, result: result)
        return
      }
      DispatchQueue.main.async {
        result(true)
      }
    }
  }

  private func handleFetch(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let database else {
      result(FlutterError(code: "not_initialized", message: "iCloud sync is not configured", details: nil))
      return
    }

    let predicate: NSPredicate
    if let args = call.arguments as? [String: Any],
       let sinceString = args["since"] as? String,
       let sinceDate = isoFormatter.date(from: sinceString) {
      predicate = NSPredicate(format: "updatedAt > %@", sinceDate as NSDate)
    } else {
      predicate = NSPredicate(value: true)
    }

    let query = CKQuery(recordType: recordType, predicate: predicate)
    database.perform(query, inZoneWith: nil) { records, error in
      if let error = error {
        self.finishWithError(code: "fetch_failed", message: "Unable to fetch clips", error: error, result: result)
        return
      }

      let payload = (records ?? []).map(self.serialize)
      DispatchQueue.main.async {
        result(payload)
      }
    }
  }

  private func save(record: CKRecord, result: @escaping FlutterResult) {
    database?.save(record) { _, error in
      if let error = error {
        self.finishWithError(code: "save_failed", message: "Unable to save clip", error: error, result: result)
        return
      }
      DispatchQueue.main.async {
        result(true)
      }
    }
  }

  private func apply(_ data: [String: Any], to record: CKRecord) {
    if let type = data["type"] as? String {
      record["type"] = type as CKRecordValue
    }
    if let content = data["content"] as? String {
      record["content"] = content as CKRecordValue
    } else {
      record["content"] = nil
    }
    if let filePath = data["filePath"] as? String {
      record["filePath"] = filePath as CKRecordValue
    } else {
      record["filePath"] = nil
    }
    if let ocrText = data["ocrText"] as? String {
      record["ocrText"] = ocrText as CKRecordValue
    } else {
      record["ocrText"] = nil
    }
    if let ocrTextId = data["ocrTextId"] as? String {
      record["ocrTextId"] = ocrTextId as CKRecordValue
    } else {
      record["ocrTextId"] = nil
    }

    if let isFavorite = data["isFavorite"] as? Bool {
      record["isFavorite"] = NSNumber(value: isFavorite)
    }
    if let isOcrExtracted = data["isOcrExtracted"] as? Bool {
      record["isOcrExtracted"] = NSNumber(value: isOcrExtracted)
    }

    if let createdAt = parseDate(data["createdAt"]) {
      record["createdAt"] = createdAt as CKRecordValue
    }
    if let updatedAt = parseDate(data["updatedAt"]) {
      record["updatedAt"] = updatedAt as CKRecordValue
    }

    if let thumbnailData = parseThumbnail(data: data["thumbnail"]) {
      record["thumbnail"] = thumbnailData as CKRecordValue
    }

    if let metadataString = metadataJSONString(from: data["metadata"]) {
      record["metadata"] = metadataString as CKRecordValue
    }

    record["schemaVersion"] = NSNumber(value: 1)
  }

  private func serialize(_ record: CKRecord) -> [String: Any] {
    var payload: [String: Any] = [
      "id": record.recordID.recordName,
      "type": record["type"] as? String ?? "text",
      "metadata": decodeMetadata(from: record["metadata"]),
      "isFavorite": (record["isFavorite"] as? NSNumber)?.boolValue ?? false,
      "isOcrExtracted": (record["isOcrExtracted"] as? NSNumber)?.boolValue ?? false,
    ]

    if let content = record["content"] as? String {
      payload["content"] = content
    }
    if let filePath = record["filePath"] as? String {
      payload["filePath"] = filePath
    }
    if let ocrText = record["ocrText"] as? String {
      payload["ocrText"] = ocrText
    }
    if let ocrTextId = record["ocrTextId"] as? String {
      payload["ocrTextId"] = ocrTextId
    }

    if let createdAt = record["createdAt"] as? Date {
      payload["createdAt"] = isoFormatter.string(from: createdAt)
    }
    if let updatedAt = record["updatedAt"] as? Date {
      payload["updatedAt"] = isoFormatter.string(from: updatedAt)
    }

    if let thumbnailData = record["thumbnail"] as? Data {
      payload["thumbnail"] = Array(thumbnailData)
    }

    return payload
  }

  private func parseDate(_ value: Any?) -> Date? {
    if let stringValue = value as? String {
      return isoFormatter.date(from: stringValue)
    }
    return nil
  }

  private func parseThumbnail(data: Any?) -> Data? {
    if let typedData = data as? FlutterStandardTypedData {
      return typedData.data
    }
    if let byteList = data as? [UInt8] {
      return Data(byteList)
    }
    if let numberList = data as? [NSNumber] {
      let bytes = numberList.map { UInt8(truncating: $0) }
      return Data(bytes)
    }
    if let anyList = data as? [Any] {
      let bytes = anyList.compactMap { element -> UInt8? in
        if let number = element as? NSNumber {
          return UInt8(truncating: number)
        }
        if let intValue = element as? Int {
          return UInt8(intValue)
        }
        return nil
      }
      return Data(bytes)
    }
    return nil
  }

  private func metadataJSONString(from value: Any?) -> String? {
    if let jsonString = value as? String {
      return jsonString
    }

    if let dictionary = value as? [String: Any],
       JSONSerialization.isValidJSONObject(dictionary),
       let data = try? JSONSerialization.data(withJSONObject: dictionary),
       let json = String(data: data, encoding: .utf8) {
      return json
    }

    if let nsDict = value as? NSDictionary,
       JSONSerialization.isValidJSONObject(nsDict),
       let data = try? JSONSerialization.data(withJSONObject: nsDict),
       let json = String(data: data, encoding: .utf8) {
      return json
    }

    return nil
  }

  private func decodeMetadata(from value: Any?) -> [String: Any] {
    if let dictionary = value as? [String: Any] {
      return dictionary
    }
    if let nsDict = value as? NSDictionary {
      var converted: [String: Any] = [:]
      for (key, val) in nsDict {
        if let keyString = key as? String {
          converted[keyString] = val
        }
      }
      return converted
    }
    guard let stringValue = value as? String,
          let data = stringValue.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return [:]
    }
    return json
  }

  private func finishWithError(
    code: String,
    message: String,
    error: Error,
    result: @escaping FlutterResult
  ) {
    DispatchQueue.main.async {
      result(FlutterError(code: code, message: message, details: error.localizedDescription))
    }
  }
}
