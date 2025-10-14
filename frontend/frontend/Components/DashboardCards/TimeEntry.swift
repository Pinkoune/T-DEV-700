//
//  TimeEntry.swift
//  frontend
//
//  Created by Jérémy Barcelo on 13/10/2025.
//

import Foundation

struct TimeEntry: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let startTime: String?
    let endTime: String?
    let timeSpent: String
    let isActive: Bool
}
