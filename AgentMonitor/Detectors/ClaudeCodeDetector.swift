import Foundation
import Darwin

struct ClaudeCodeDetector: AgentDetector {
    let agentType: AgentType = .claudeCode

    func detect() async -> [AgentInstance] {
        let pids = getAllPIDs()
        var instances: [AgentInstance] = []

        for pid in pids {
            guard isClaudeProcess(pid) else { continue }
            guard let cwd = getWorkingDirectory(pid) else { continue }
            let startTime = getProcessStartTime(pid) ?? Date()
            let sessionData = loadSessionData(for: cwd)

            instances.append(
                AgentInstance(
                    agentType: .claudeCode,
                    pid: pid,
                    workingDirectory: cwd,
                    modelName: sessionData?.modelName,
                    sessionTitle: sessionData?.sessionTitle,
                    sessionStartTime: startTime
                )
            )
        }

        return instances
    }

    // MARK: - Process detection

    private func getAllPIDs() -> [pid_t] {
        let count = proc_listallpids(nil, 0)
        guard count > 0 else { return [] }

        var pids = [pid_t](repeating: 0, count: Int(count) + 16)
        let actual = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard actual > 0 else { return [] }

        return pids.prefix(Int(actual)).filter { $0 > 0 }
    }

    private func isClaudeProcess(_ pid: pid_t) -> Bool {
        // Claude Code now ships versioned binaries at:
        // ~/.local/share/claude/versions/2.x.y
        // proc_name returns the version string (e.g. "2.1.63"), not "claude"
        // Use proc_pidpath to check the full executable path instead.
        var pathBuf = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let result = proc_pidpath(pid, &pathBuf, UInt32(pathBuf.count))
        guard result > 0 else { return false }
        let path = String(cString: pathBuf)
        return path.contains("/claude/") || path.hasSuffix("/claude")
    }

    private func getWorkingDirectory(_ pid: pid_t) -> String? {
        var vnodeInfo = proc_vnodepathinfo()
        let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &vnodeInfo, size)
        guard result > 0 else { return nil }

        return withUnsafePointer(to: &vnodeInfo.pvi_cdir.vip_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) { cstr in
                let path = String(cString: cstr)
                return path.isEmpty ? nil : path
            }
        }
    }

    private func getProcessStartTime(_ pid: pid_t) -> Date? {
        var bsdInfo = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        let result = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsdInfo, size)
        guard result > 0 else { return nil }

        let seconds = TimeInterval(bsdInfo.pbi_start_tvsec)
        let microseconds = TimeInterval(bsdInfo.pbi_start_tvusec) / 1_000_000
        return Date(timeIntervalSince1970: seconds + microseconds)
    }

    // MARK: - Session data

    private struct SessionData {
        let modelName: String?
        let sessionTitle: String?
    }

    /// Scans ~/.claude/projects/{cwd-as-dir}/*.jsonl files to find the most recent session
    /// that has actual assistant messages (skipping empty stub files). Returns model name
    /// and session title (from session-meta summary if available, else first user message).
    private func loadSessionData(for cwd: String) -> SessionData? {
        // Claude Code stores projects as dirs named by replacing '/' with '-' in the path.
        // e.g. /Users/foo/Sites/bar -> -Users-foo-Sites-bar
        let projectDirName = cwd.replacingOccurrences(of: "/", with: "-")
        let projectDir = NSHomeDirectory() + "/.claude/projects/" + projectDirName
        let sessionMetaDir = NSHomeDirectory() + "/.claude/usage-data/session-meta"

        let fm = FileManager.default
        guard fm.fileExists(atPath: projectDir),
              let files = try? fm.contentsOfDirectory(atPath: projectDir) else { return nil }

        // Collect all top-level .jsonl files sorted by modification date, newest first.
        let jsonlFiles = files
            .filter { $0.hasSuffix(".jsonl") }
            .compactMap { name -> (String, Date)? in
                let path = projectDir + "/" + name
                guard let attrs = try? fm.attributesOfItem(atPath: path),
                      let mod = attrs[.modificationDate] as? Date else { return nil }
                return (name, mod)
            }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }

        // Scan files newest-first; skip stubs (no assistant messages).
        for jsonlName in jsonlFiles {
            let path = projectDir + "/" + jsonlName
            guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
            let lines = content.components(separatedBy: "\n")

            var modelName: String?
            var firstUserMessage: String?
            var hasAssistantMessages = false

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty,
                      let data = trimmed.data(using: .utf8),
                      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else { continue }

                let type = obj["type"] as? String

                // Extract model from first assistant message.
                if type == "assistant", !hasAssistantMessages {
                    hasAssistantMessages = true
                    if let message = obj["message"] as? [String: Any],
                       let model = message["model"] as? String, !model.isEmpty {
                        modelName = model
                    }
                } else if type == "assistant" {
                    hasAssistantMessages = true
                }

                // Extract first real user message (skip meta/system content).
                if type == "user", firstUserMessage == nil {
                    if let message = obj["message"] as? [String: Any] {
                        let content = message["content"]
                        if let text = content as? String,
                           !text.isEmpty, !text.hasPrefix("<") {
                            firstUserMessage = text
                        } else if let parts = content as? [[String: Any]] {
                            for part in parts {
                                if part["type"] as? String == "text",
                                   let text = part["text"] as? String,
                                   !text.isEmpty, !text.hasPrefix("<") {
                                    firstUserMessage = text
                                    break
                                }
                            }
                        }
                    }
                }
            }

            // Skip stubs with no assistant messages.
            guard hasAssistantMessages else { continue }

            // Try session-meta for an AI-generated summary (better than first prompt).
            let sessionUUID = String(jsonlName.dropLast(6)) // strip .jsonl
            let metaPath = sessionMetaDir + "/" + sessionUUID + ".json"
            var sessionTitle: String? = firstUserMessage

            if let metaData = try? Data(contentsOf: URL(fileURLWithPath: metaPath)),
               let metaJson = try? JSONSerialization.jsonObject(with: metaData) as? [String: Any],
               let summary = metaJson["summary"] as? String, !summary.isEmpty {
                sessionTitle = summary
            }

            return SessionData(modelName: modelName, sessionTitle: sessionTitle)
        }

        return nil
    }
}
