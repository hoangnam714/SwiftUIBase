//
//  String+Extension.swift
//  SwiftUIBase
//
//  Created by Aland on 12/5/26.
//

import Foundation

extension String {
    // MARK: - ISO 8601 Date Formatting
    
    /// Parses an ISO8601 date string and formats it as `dd/MM/yyyy`.
    ///
    /// - Returns: Formatted date string, or empty string when parsing fails.
    public func formatDateISO8601() -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: self) else {
            return ""
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM/yyyy"
        outputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        return outputFormatter.string(from: date)
    }
    
    // MARK: - Relative Time
    
    /// Converts an ISO8601 date string into relative time text.
    ///
    /// Example outputs: "Just now", "3 hours ago", "2 weeks ago".
    ///
    /// - Parameters:
    ///   - locale: Locale used for plural formatting.
    ///   - referenceDate: Reference date used for comparison (default is now).
    /// - Returns: Relative time string.
    public func relativeUpdatedAt(locale: Locale = .current, referenceDate: Date = Date()) -> String {
        guard let updatedDate = self.iso8601DateWithFractionalSeconds() else {
            return NSLocalizedString("Just now", comment: "Recent update fallback text")
        }
        
        if updatedDate >= referenceDate {
            return NSLocalizedString("Just now", comment: "Recent update fallback text")
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute], from: updatedDate, to: referenceDate)
        
        if let years = components.year, years > 0 {
            return localizedRelativeTime(
                count: years,
                singularKey: "1 year ago",
                pluralFormatKey: "%lld years ago",
                locale: locale
            )
        }
        
        if let months = components.month, months > 0 {
            return localizedRelativeTime(
                count: months,
                singularKey: "1 month ago",
                pluralFormatKey: "%lld months ago",
                locale: locale
            )
        }
        
        if let weeks = components.weekOfYear, weeks > 0 {
            return localizedRelativeTime(
                count: weeks,
                singularKey: "1 week ago",
                pluralFormatKey: "%lld weeks ago",
                locale: locale
            )
        }
        
        if let days = components.day, days > 0 {
            return localizedRelativeTime(
                count: days,
                singularKey: "1 day ago",
                pluralFormatKey: "%lld days ago",
                locale: locale
            )
        }
        
        if let hours = components.hour, hours > 0 {
            return localizedRelativeTime(
                count: hours,
                singularKey: "1 hour ago",
                pluralFormatKey: "%lld hours ago",
                locale: locale
            )
        }
        
        if let minutes = components.minute, minutes > 0 {
            return localizedRelativeTime(
                count: minutes,
                singularKey: "1 minute ago",
                pluralFormatKey: "%lld minutes ago",
                locale: locale
            )
        }
        
        return NSLocalizedString("Just now", comment: "Recent update fallback text")
    }
    
    // MARK: - Common Date Output
    
    /// Parses ISO8601 string (with or without fractional seconds) and formats as `dd/MM/yyyy`.
    ///
    /// - Returns: Formatted date string, or empty string when parsing fails.
    public func formattedDate_ddMMyyyy() -> String {
        guard let date = iso8601DateWithFractionalSeconds() else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    // MARK: - Date Parsing & Conversion
    
    /// Parses string to `Date` using a custom input format.
    ///
    /// - Parameters:
    ///   - inputFormat: Input date format (for example: `yyyy-MM-dd HH:mm:ss`).
    ///   - locale: Formatter locale. Default is `en_US_POSIX`.
    ///   - timeZone: Formatter time zone. Default is current time zone.
    /// - Returns: Parsed `Date` if valid, otherwise `nil`.
    public func toDate(
        inputFormat: String,
        locale: Locale = Locale(identifier: "en_US_POSIX"),
        timeZone: TimeZone = .current
    ) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = inputFormat
        return formatter.date(from: self)
    }
    
    /// Converts date string from one format to another.
    ///
    /// - Parameters:
    ///   - inputFormat: Current format of the string.
    ///   - outputFormat: Target format for output.
    ///   - locale: Locale used by formatter.
    ///   - inputTimeZone: Time zone used to parse input.
    ///   - outputTimeZone: Time zone used to generate output.
    /// - Returns: Converted date string, or empty string when parsing fails.
    public func convertDateFormat(
        from inputFormat: String,
        to outputFormat: String,
        locale: Locale = Locale(identifier: "en_US_POSIX"),
        inputTimeZone: TimeZone = .current,
        outputTimeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = inputTimeZone
        formatter.dateFormat = inputFormat
        
        guard let date = formatter.date(from: self) else {
            return ""
        }
        
        formatter.timeZone = outputTimeZone
        formatter.dateFormat = outputFormat
        return formatter.string(from: date)
    }
    
    /// Parses ISO8601 string and formats to a custom output format.
    ///
    /// - Parameter outputFormat: Desired output format.
    /// - Returns: Formatted date string, or empty string when parsing fails.
    public func formatDateFromISO8601(to outputFormat: String = "dd/MM/yyyy") -> String {
        guard let date = iso8601DateWithFractionalSeconds() else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = outputFormat
        return formatter.string(from: date)
    }
    
    /// Convenience wrapper to convert a date string from input format to output format.
    ///
    /// - Parameters:
    ///   - inputFormat: Format of current string.
    ///   - outputFormat: Target output format. Default is `dd/MM/yyyy`.
    ///   - locale: Formatter locale.
    /// - Returns: Converted date string, or empty string when parsing fails.
    public func formatDate(
        from inputFormat: String,
        to outputFormat: String = "dd/MM/yyyy",
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> String {
        convertDateFormat(
            from: inputFormat,
            to: outputFormat,
            locale: locale
        )
    }
    
    // MARK: - Private Helpers
    
    private func iso8601DateWithFractionalSeconds() -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = fractionalFormatter.date(from: self) {
            return date
        }
        
        let normalFormatter = ISO8601DateFormatter()
        normalFormatter.formatOptions = [.withInternetDateTime]
        return normalFormatter.date(from: self)
    }
    
    private func localizedRelativeTime(
        count: Int,
        singularKey: String,
        pluralFormatKey: String,
        locale: Locale
    ) -> String {
        if count == 1 {
            return NSLocalizedString(singularKey, comment: "Relative time singular")
        }
        
        let format = NSLocalizedString(pluralFormatKey, comment: "Relative time plural")
        return String(format: format, locale: locale, count)
    }
}
