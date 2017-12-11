//
//  RLP.swift
//  web3swift
//
//  Created by Alexander Vlasov on 09.12.2017.
//  Copyright © 2017 Bankex Foundation. All rights reserved.
//

import Foundation
import Sodium
import BigInt

protocol ArrayType {}
extension Array : ArrayType {}

struct RLP {
    static var length56 = BigUInt(UInt(56))
    static var lengthMax = (BigUInt(UInt(1)) << 256)
    
    static func encode(_ element: AnyObject) -> Data? {
        if let string = element as? String {
            return encode(string)
            
        } else if let data = element as? Data {
            return encode(data)
        }
        else if let biguint = element as? BigUInt {
            return encode(biguint)
        }
        return nil;
    }
    
    static func encode(_ string: String) -> Data? {
        let sodium = Sodium()
        if let hexData = sodium.utils.hex2bin(string) {
            return encode(hexData)
        }
        guard let data = string.data(using: .utf8) else {return nil}
        return encode(data)
    }
    
    static func encode(_ number: Int) -> Data? {
        guard number >= 0 else {return nil}
        let uint = UInt(number)
        return encode(uint)
    }
    
    static func encode(_ number: UInt) -> Data? {
        let biguint = BigUInt(number)
        return encode(biguint)
    }
    
    static func encode(_ number: BigUInt) -> Data? {
        let encoded = number.serialize()
        return encode(encoded)
    }
    
    static func encode(_ data: Data) -> Data? {
        if (data.count == 1 && data.bytes[0] < UInt8(0x80)) {
            return data
        } else {
            guard let length = encodeLength(data.count, offset: UInt8(0x80)) else {return nil}
            var encoded = Data()
            encoded.append(length)
            encoded.append(data)
            return encoded
        }
    }
    
    static func encodeLength(_ length: Int, offset: UInt8) -> Data? {
        if (length < 0) {
            return nil;
        }
        let bigintLength = BigUInt(UInt(length))
        return encodeLength(bigintLength, offset: offset)
    }
    
    static func encodeLength(_ length: BigUInt, offset: UInt8) -> Data? {
        if (length < length56) {
            let encodedLength = length + BigUInt(UInt(offset))
            guard (encodedLength.bitWidth <= 8) else {return nil}
            return encodedLength.serialize()
        } else if (length < lengthMax) {
            let encodedLength = length.serialize()
            let len = BigUInt(UInt(encodedLength.count))
            guard let prefix = lengthToBinary(len) else {return nil}
            let lengthPrefix = prefix + offset + UInt8(55)
            var encoded = Data([lengthPrefix])
            encoded.append(encodedLength)
            return encoded
        }
        return nil
    }
    
    internal static func lengthToBinary(_ length: BigUInt) -> UInt8? {
        if (length == 0) {
            return UInt8(0)
        }
        let divisor = BigUInt(256)
        var encoded = Data()
        guard let prefix = lengthToBinary(length/divisor) else {return nil}
        let suffix = length % divisor
        
        var prefixData = Data([prefix])
        if (prefix == UInt8(0)) {
            prefixData = Data()
        }
        let suffixData = suffix.serialize()
        
        encoded.append(prefixData)
        encoded.append(suffixData)
        guard encoded.count == 1 else {return nil}
        return encoded.bytes[0]
    }
    
    static func encode(_ elements: Array<AnyObject>) -> Data? {
        var encodedData = Data()
        for e in elements {
            guard let encoded = encode(e) else {return nil}
            encodedData.append(encoded)
        }
        guard var encodedLength = encodeLength(encodedData.count, offset: UInt8(0xc0)) else {return nil}
        if (encodedLength != Data()) {
            encodedLength.append(encodedData)
        }
        return encodedLength
    }
    
    static func encode(_ elements: [Any]) -> Data? {
        var encodedData = Data()
        for el in elements {
            let e = el as AnyObject
            guard let encoded = encode(e) else {return nil}
            encodedData.append(encoded)
        }
        guard var encodedLength = encodeLength(encodedData.count, offset: UInt8(0xc0)) else {return nil}
        if (encodedLength != Data()) {
            encodedLength.append(encodedData)
        }
        return encodedLength
    }
    
//    static func encode(_ dataArray: [Data]) -> Data? {
//        var encodedData = Data()
//        for d in dataArray {
//            guard let encoded = encode(d) else {return nil}
//            encodedData.append(encoded)
//        }
//        guard var encodedLength = encodeLength(encodedData.count, offset: UInt8(0xc0)) else {return nil}
//        if (encodedLength != Data()) {
//            encodedLength.append(encodedData)
//        }
//        return encodedLength
//    }
//    
//    static func encode(_ stringArray: [String]) -> Data? {
//        var encodedData = Data()
//        for s in stringArray {
//            guard let encoded = encode(s) else {return nil}
//            encodedData.append(encoded)
//        }
//        guard var encodedLength = encodeLength(encodedData.count, offset: UInt8(0xc0)) else {return nil}
//        encodedLength.append(encodedData)
//        return encodedLength
//    }
//    
//    static func encode(_ biguintArray: [BigUInt]) -> Data? {
//        var encodedData = Data()
//        for biguint in biguintArray {
//            guard let encoded = encode(biguint) else {return nil}
//            encodedData.append(encoded)
//        }
//        guard var encodedLength = encodeLength(encodedData.count, offset: UInt8(0xc0)) else {return nil}
//        encodedLength.append(encodedData)
//        return encodedLength
//    }
}

