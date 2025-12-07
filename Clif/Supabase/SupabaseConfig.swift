import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: "https://vedyfilksyovwnjvjxmi.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZlZHlmaWxrc3lvdnduanZqeG1pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxMTc2NDYsImV4cCI6MjA4MDY5MzY0Nn0.EkC5i_6rboGLNwlufiD8SLzjYhDQFODXPS8y7R-Uu-I"
    
    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey,
        options: SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                emitLocalSessionAsInitialSession: true
            )
        )
    )
}
