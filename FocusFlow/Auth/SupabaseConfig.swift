import Foundation

struct SupabaseConfig {
    static let shared = SupabaseConfig()

    /// Example:
    /// projectURL = URL(string: "https://yusbyoyutjoziawtecjo.supabase.co")!
    let projectURL: URL

    /// Same anon key you already ship in AuthAPI.swift (safe to ship).
    let anonKey: String

    private init() {
        // ✅ Use your project URL
        self.projectURL = URL(string: "https://yusbyoyutjoziawtecjo.supabase.co")!

        // ✅ Paste the same anon key string you already use in AuthAPI.swift / UserProfileAPI.swift
        self.anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1c2J5b3l1dGpvemlhd3RlY2pvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwNjAwMzEsImV4cCI6MjA4MDYzNjAzMX0.flWK0SGk_vyP4YBwmZqXeWkXPcrgPlMSvuqwYgFiT-8"
    }
}
