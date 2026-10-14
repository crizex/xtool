import Foundation
import ArgumentParser
import XKit
import Dependencies
import XUtils

struct SignCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sign",
        abstract: "Codesign an already built app",
        discussion: """
        Signs a .app produced by `xtool dev build` (without --sign) in place, \
        so the bundle can be post-processed between building and signing.
        """
    )

    @Argument(help: "The .app to sign") var path: String

    @Flag(
        name: .shortAndLong,
        help: "Output a .ipa file instead of a .app"
    ) var ipa = false

    func run() async throws {
        guard let token = try AuthToken.savedIfPresent() else {
            throw Console.Error("`sign` requires logging in with `xtool auth`")
        }
        try await Self.finish(app: URL(fileURLWithPath: path), signingAuthToken: token, ipa: ipa)
    }

    static func finish(app url: URL, signingAuthToken: AuthToken?, ipa: Bool) async throws {
        if let signingAuthToken {
            let installDelegate = XToolInstallerDelegate()
            let installer = IntegratedInstaller(
                auth: signingAuthToken.authData(),
                delegate: installDelegate
            )
            do {
                defer { print() }
                try await installer.signInPlace(app: url)
            } catch let error as CancellationError {
                throw error
            } catch {
                print("Error: \(error)")
                throw ExitCode.failure
            }
        }

        let finalURL: URL
        if ipa {
            @Dependency(\.zipCompressor) var compressor
            finalURL = url.deletingPathExtension().appendingPathExtension("ipa")
            let tmpDir = try TemporaryDirectory(name: "Payload")
            let payloadDir = tmpDir.url
            try FileManager.default.moveItem(at: url, to: payloadDir.appendingPathComponent(url.lastPathComponent))
            let ipaURL = try await compressor.compress(directory: payloadDir) { progress in
                if let progress {
                    let percent = Int(progress * 100)
                    print("\rPackaging... \(percent)%", terminator: "")
                } else {
                    print("\rPackaging...", terminator: "")
                }
            }
            print()
            try? FileManager.default.removeItem(at: finalURL)
            try FileManager.default.moveItem(at: ipaURL, to: finalURL)
        } else {
            finalURL = url
        }

        print("Wrote to \(finalURL.path)")
    }
}
