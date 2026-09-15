import Foundation
import CommonCrypto

// MARK: - TL Writer (Binary Serialization)
public final class TLWriter {
    public private(set) var data = Data()
    
    public init() {}
    
    public func writeInt32(_ value: Int32) {
        var v = value.littleEndian
        data.append(UnsafeBufferPointer(start: &v, count: 1))
    }
    
    public func writeUInt32(_ value: UInt32) {
        var v = value.littleEndian
        data.append(UnsafeBufferPointer(start: &v, count: 1))
    }
    
    public func writeInt64(_ value: Int64) {
        var v = value.littleEndian
        data.append(UnsafeBufferPointer(start: &v, count: 1))
    }
    
    public func writeDouble(_ value: Double) {
        var v = value.bitPattern.littleEndian
        data.append(UnsafeBufferPointer(start: &v, count: 1))
    }
    
    public func writeBytes(_ bytes: Data) {
        data.append(bytes)
    }
    
    public func writeString(_ string: String) {
        guard let strData = string.data(using: .utf8) else {
            writeBytes(Data([0, 0, 0, 0]))
            return
        }
        let length = strData.count
        var padding = 0
        if length <= 253 {
            data.append(UInt8(length))
            data.append(strData)
            padding = (4 - ((length + 1) % 4)) % 4
        } else {
            data.append(254)
            data.append(UInt8(length & 0xFF))
            data.append(UInt8((length >> 8) & 0xFF))
            data.append(UInt8((length >> 16) & 0xFF))
            data.append(strData)
            padding = (4 - (length % 4)) % 4
        }
        if padding > 0 {
            data.append(Data(repeating: 0, count: padding))
        }
    }
}

// MARK: - TL Reader (Binary Deserialization)
public final class TLReader {
    private let data: Data
    public private(set) var offset: Int = 0
    
    public init(data: Data) {
        self.data = data
    }
    
    public var remaining: Int {
        return max(0, data.count - offset)
    }
    
    public func readInt32() -> Int32 {
        guard offset + 4 <= data.count else { return 0 }
        let value = data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: Int32.self) }
        offset += 4
        return Int32(littleEndian: value)
    }
    
    public func readUInt32() -> UInt32 {
        guard offset + 4 <= data.count else { return 0 }
        let value = data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: UInt32.self) }
        offset += 4
        return UInt32(littleEndian: value)
    }
    
    public func readInt64() -> Int64 {
        guard offset + 8 <= data.count else { return 0 }
        let value = data.subdata(in: offset..<offset+8).withUnsafeBytes { $0.load(as: Int64.self) }
        offset += 8
        return Int64(littleEndian: value)
    }
    
    public func readBytes(_ count: Int) -> Data {
        let actualCount = min(count, remaining)
        let sub = data.subdata(in: offset..<offset+actualCount)
        offset += actualCount
        return sub
    }
    
    public func readString() -> String {
        guard remaining > 0 else { return "" }
        var length = Int(data[offset])
        var headerLength = 1
        
        if length == 254 {
            guard remaining >= 4 else { return "" }
            length = Int(data[offset+1]) | (Int(data[offset+2]) << 8) | (Int(data[offset+3]) << 16)
            headerLength = 4
        }
        
        offset += headerLength
        guard remaining >= length else { return "" }
        let strData = data.subdata(in: offset..<offset+length)
        offset += length
        
        // Skip padding
        let total = length + headerLength
        let padding = (4 - (total % 4)) % 4
        offset += min(padding, remaining)
        
        return String(data: strData, encoding: .utf8) ?? ""
    }
}

// MARK: - Telegram Crypto (SHA1, SHA256, Random)
public enum TGCrypto {
    public static func sha1(_ data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
    
    public static func sha256(_ data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
    
    public static func randomBytes(count: Int) -> Data {
        var data = Data(count: count)
        _ = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!)
        }
        return data
    }
}
