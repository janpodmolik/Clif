# Claude Code Project Rules

## File Creation Policy

**NEVER create new files automatically.**

When a new file needs to be created:
1. Stop work immediately
2. Tell the user which file you want to create
3. Explain the purpose of the file
4. Ask which target it should belong to (e.g., main app, DeviceActivityReport extension, etc.)
5. Wait for explicit approval before creating the file

This applies to all file types: Swift, entitlements, plist, resources, etc.

## External Libraries & Documentation

**Always use Context7 MCP server for documentation lookup.**

When implementing or working with external libraries (e.g., Supabase, Firebase, etc.):
1. Use Context7 MCP server to fetch the latest documentation
2. Do not rely on outdated knowledge - always verify current API usage
3. This ensures we use up-to-date patterns and avoid deprecated methods

## Architecture

**This project uses MV (Model-View) architecture.**

Guidelines:
- Views are SwiftUI views that directly observe and interact with models
- Models contain the data and business logic
- Use @Observable (iOS 17+) or ObservableObject for reactive state
- Keep views simple - they should primarily handle UI rendering
- Avoid unnecessary abstraction layers (no ViewModels, Coordinators unless explicitly needed)
