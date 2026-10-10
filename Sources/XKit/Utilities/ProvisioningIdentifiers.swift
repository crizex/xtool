//
//  ProvisioningIdentifiers.swift
//  XKit
//
//  Created by Kabir Oberai on 14/10/19.
//  Copyright © 2019 Kabir Oberai. All rights reserved.
//

import Foundation

enum ProvisioningIdentifiers {}

extension ProvisioningIdentifiers {

    static let idPrefix = "XTL-"
    static let groupPrefix = "group."
    static let namePrefix = "XTool "

    static func sanitize(identifier: String) -> String {
        guard identifier.hasPrefix(Self.idPrefix) else { return identifier }
        return identifier.split(separator: ".").dropFirst().joined(separator: ".")
    }

    /// Free teams share a global bundle ID namespace, so the ID is prefixed with a
    /// per-identity marker. Paid teams own their bundle IDs and keep them as-is.
    static func identifier(fromSanitized sanitized: String, context: SigningContext, isFreeTeam: Bool) -> String {
        guard isFreeTeam else { return sanitized }
        let uuid = context.auth.identityID.split(separator: "-")[0].uppercased()
        return "\(Self.idPrefix)\(uuid).\(sanitized)"
    }

    static func safeify(identifier: String) -> String {
        identifier.replacingOccurrences(of: ".", with: " ")
    }

    static func sanitize(groupID: DeveloperServicesAppGroup.GroupID) -> String {
        var id = groupID.rawValue
        if id.hasPrefix(Self.groupPrefix) { id.removeFirst(Self.groupPrefix.count) }
        return sanitize(identifier: id)
    }

    static func groupID(fromSanitized sanitized: String, context: SigningContext, isFreeTeam: Bool) -> DeveloperServicesAppGroup.GroupID {
        .init(rawValue: "\(Self.groupPrefix)\(identifier(fromSanitized: sanitized, context: context, isFreeTeam: isFreeTeam))")
    }

    static func groupName(fromSanitized sanitized: String) -> String {
        "\(Self.namePrefix)group \(safeify(identifier: sanitized))"
    }

    static func appName(fromSanitized sanitized: String) -> String {
        "\(Self.namePrefix)\(safeify(identifier: sanitized))"
    }

}
