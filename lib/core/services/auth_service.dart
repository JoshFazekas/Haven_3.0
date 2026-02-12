// ═══════════════════════════════════════════════════════════════════
//  AuthService is DEPRECATED — use HavenApi instead.
//
//  All HTTP calls now live in haven_api.dart (single source of truth).
//  This file only re-exports HavenApiException as AuthException so
//  existing catch blocks keep compiling while we migrate them.
// ═══════════════════════════════════════════════════════════════════

import 'package:haven/core/services/haven_api.dart';

/// Thin wrapper kept only for backward-compatible `on AuthException` catches.
/// New code should catch [HavenApiException] directly.
typedef AuthException = HavenApiException;
