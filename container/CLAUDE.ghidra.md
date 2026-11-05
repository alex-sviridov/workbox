
## Reverse engineering: REA + Ghidra
- The `rea` MCP server is registered, with the `reverse-engineer-anything` skill. Use them for binary analysis.
  The same features are available from the shell as `rea <command>` (see `rea --help`).
- The deep-analysis provider is Ghidra 12.1.4 (headless, read-only, one ephemeral project per session).
  It handles native Windows PE (.exe/.dll, x86 and x86-64), ELF, Mach-O and more.
- .NET assemblies: use REA's managed-code tools (`inspect-managed-*`). They read metadata and CIL without Ghidra.
- Samples live in `/work/samples`. Always pass absolute paths.
- The first Ghidra query on a binary runs a full import and auto-analysis. It can take minutes on large files,
  so it is not hung. Later queries in the same session are fast.
- Analysis is static only. There is no Wine and no Windows, so never try to run the target binaries.
- Readiness check: `rea doctor --format json`. Startup logs: `~/rea-setup.log`, `~/rea-doctor.json`.
- JDK 21 is also installed (`JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64`).
