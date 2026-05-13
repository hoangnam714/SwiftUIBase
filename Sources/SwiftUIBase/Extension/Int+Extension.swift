//
//  Int+Extension.swift
//  SwiftUIBase
//
//  Created by Aland on 12/5/26.
//

import Foundation

extension Int {
    // MARK: - Number Formatting
    
    /// Converts a number to compact text (K, M, B, T).
    ///
    /// Examples:
    /// - 1_250 -> "1.2K"
    /// - 2_000_000 -> "2M"
    ///
    /// - Returns: Abbreviated number string.
    public func abbreviateNumber() -> String {
        let num = Double(abs(self))
        let sign = self < 0 ? "-" : ""
        let units: [(Double, String)] = [
            (1_000_000_000_000, "T"),
            (1_000_000_000,     "B"),
            (1_000_000,         "M"),
            (1_000,             "K")
        ]
        for (threshold, suffix) in units {
            if num >= threshold {
                let value = num / threshold
                let fmt = NumberFormatter()
                fmt.locale = Locale(identifier: "en_US_POSIX")
                fmt.minimumFractionDigits = 0
                fmt.maximumFractionDigits = value < 10 ? 1 : 0
                let s = fmt.string(from: NSNumber(value: value)) ?? "\(value)"
                return "\(sign)\(s)\(suffix)"
            }
        }
        return "\(self)"
    }
    
    // MARK: - View Count Display
    
    /// Converts number to Vietnamese view-count text.
    ///
    /// Examples:
    /// - 980 -> "980 lượt xem"
    /// - 12_300 -> "12.3K lượt xem"
    ///
    /// - Returns: Human-readable view count string.
    public func viewCountText() -> String {
        if self < 0 {
            return "0 lượt xem"
        }
        return "\(abbreviateNumber()) lượt xem"
    }

}

