import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: "https://owodjfgrmtltmfpqvlot.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93b2RqZmdybXRsdG1mcHF2bG90Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1MjA5MDUsImV4cCI6MjA4NjA5NjkwNX0.7Lb0Ke204EEvNLEOq1i9lx0T8UnvM_xWDaRHgadRwAg"

    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey,
        options: .init(
            auth: .init(
                redirectToURL: URL(string: "uuumi://auth/callback"),
                emitLocalSessionAsInitialSession: true
            )
        )
    )
}
