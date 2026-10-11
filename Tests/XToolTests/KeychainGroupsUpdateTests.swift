import Foundation
import Testing
@testable import XKit

private func entitlements(keychainGroups: [String]?) throws -> Entitlements {
    var ents: [Entitlement] = []
    if let keychainGroups { ents.append(KeychainAccessGroupsEntitlement(rawValue: keychainGroups)) }
    return try Entitlements(entitlements: ents)
}

private func keychainGroups(_ entitlements: Entitlements) throws -> [String]? {
    try entitlements.entitlements().compactMap { $0 as? KeychainAccessGroupsEntitlement }.first?.rawValue
}

@Test func keychainGroupsKeepDeclaredTeamGroups() throws {
    var ents = try entitlements(keychainGroups: [
        "$(AppIdentifierPrefix)com.example.app",
        "$(AppIdentifierPrefix)com.example.shared",
    ])
    try ents.update(teamID: .init(rawValue: "ABCDE12345"), bundleID: "com.example.app")
    #expect(try keychainGroups(ents) == ["ABCDE12345.com.example.app", "ABCDE12345.com.example.shared"])
}

@Test func keychainGroupsDropForeignPrefixes() throws {
    var ents = try entitlements(keychainGroups: ["OTHERTEAM1.com.example.shared"])
    try ents.update(teamID: .init(rawValue: "ABCDE12345"), bundleID: "com.example.app")
    #expect(try keychainGroups(ents) == ["ABCDE12345.com.example.app"])
}

@Test func keychainGroupsDefaultWhenUndeclared() throws {
    var ents = try entitlements(keychainGroups: nil)
    try ents.update(teamID: .init(rawValue: "ABCDE12345"), bundleID: "com.example.app")
    #expect(try keychainGroups(ents) == ["ABCDE12345.com.example.app"])
}
