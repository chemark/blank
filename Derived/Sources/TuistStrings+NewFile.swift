// swiftlint:disable:this file_name
// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
// Generated using tuist — https://github.com/tuist/tuist

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
public enum NewFileStrings: Sendable {

  public enum App: Sendable {
    /// Create a new empty file from Finder's right-click menu, then rename it with any extension you need.
    public static let subtitle = NewFileStrings.tr("Localizable", "app.subtitle")
  }

  public enum Privacy: Sendable {
    /// Blank does not use network access, analytics, background daemons, file indexing, or content scanning. It only creates an empty Untitled file in the Finder folder you act on.
    public static let body = NewFileStrings.tr("Localizable", "privacy.body")
    /// Privacy
    public static let title = NewFileStrings.tr("Localizable", "privacy.title")
  }

  public enum Setup: Sendable {
    /// Open System Settings, find Extensions, then enable Blank. After it is enabled, right-click a folder and choose New File.
    public static let body = NewFileStrings.tr("Localizable", "setup.body")
    /// Open Extension Settings
    public static let openSettings = NewFileStrings.tr("Localizable", "setup.open_settings")
    /// Relaunch Finder
    public static let relaunchFinder = NewFileStrings.tr("Localizable", "setup.relaunch_finder")
    /// Enable the Finder extension
    public static let title = NewFileStrings.tr("Localizable", "setup.title")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension NewFileStrings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = Bundle.module.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
// swiftformat:enable all
// swiftlint:enable all
