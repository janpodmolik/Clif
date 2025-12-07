//
//  TotalActivityView.swift
//  DeviceActivityReport
//
//  Created by Jan Podmolík on 07.12.2025.
//

import FamilyControls
import SwiftUI

struct TotalActivityView: View {
    let data: ActivityReportData
    
    init(totalActivity: ActivityReportData) {
        self.data = totalActivity
    }
    
    private var progressColor: Color {
        if data.progress >= 1.0 { return .red }
        if data.progress >= 0.8 { return .orange }
        return .blue
    }
    
    private var limitText: String {
        let minutes = Int(data.dailyLimit / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Left side - Progress circle with time
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: min(data.progress, 1.0))
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: data.progress)
                
                // Time text
                VStack(spacing: 2) {
                    Text(data.formattedTotal.isEmpty ? "0m" : data.formattedTotal)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 1)
                    
                    Text(limitText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 120, height: 120)
            
            // Right side - Scrollable app list
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    if data.apps.isEmpty {
                        Text("Žádná aktivita")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(data.apps) { app in
                            AppRowView(app: app)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
    }
}

struct AppRowView: View {
    let app: AppActivityData
    
    var body: some View {
        HStack(spacing: 12) {
            if let token = app.token {
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: 32, height: 32)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
            } else {
                Image(systemName: "app.fill")
                    .frame(width: 32, height: 32)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                    .foregroundColor(.secondary)
            }
            
            Text(app.formattedDuration)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    TotalActivityView(totalActivity: ActivityReportData(
        totalDuration: 22620, // 6h 17m
        formattedTotal: "6h 17m",
        dailyLimit: 3600, // 1h
        progress: 6.28,
        apps: []
    ))
}
