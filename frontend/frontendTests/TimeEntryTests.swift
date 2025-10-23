//
//  TimeEntryTests.swift
//  frontendTests
//
//  Created by Jérémy Barcelo on 17/10/2025.
//

import Testing
@testable import frontend

@Suite("TimeEntry Tests")
struct TimeEntryTests {
    
    @Test("Creating a basic TimeEntry")
    func testBasicCreation() {
        let entry = TimeEntry(
            id: "test-1",
            title: "Test Day",
            subtitle: "Test Subtitle",
            startTime: "9:00",
            endTime: "17:00",
            timeSpent: "8:00",
            isActive: false
        )
        
        #expect(entry.id == "test-1")
        #expect(entry.title == "Test Day")
        #expect(entry.subtitle == "Test Subtitle")
        #expect(entry.startTime == "9:00")
        #expect(entry.endTime == "17:00")
        #expect(entry.timeSpent == "8:00")
        #expect(entry.isActive == false)
    }
    
    @Test("Creating an active TimeEntry without end time")
    func testActiveEntry() {
        let entry = TimeEntry(
            id: "active-1",
            title: "Today",
            subtitle: "Current",
            startTime: "8:30",
            endTime: nil,
            timeSpent: "4:30",
            isActive: true
        )
        
        #expect(entry.isActive == true)
        #expect(entry.endTime == nil)
        #expect(entry.startTime != nil)
    }
    
    @Test("TimeEntry with empty strings")
    func testEmptyStrings() {
        let entry = TimeEntry(
            id: "",
            title: "",
            subtitle: "",
            startTime: "",
            endTime: "",
            timeSpent: "",
            isActive: false
        )
        
        #expect(entry.id == "")
        #expect(entry.title == "")
    }
    
    @Test("Two TimeEntries with same ID are equal")
    func testIdentifiableConformance() {
        let entry1 = TimeEntry(
            id: "same-id",
            title: "Title 1",
            subtitle: "Sub 1",
            startTime: "9:00",
            endTime: "17:00",
            timeSpent: "8:00",
            isActive: false
        )
        
        let entry2 = TimeEntry(
            id: "same-id",
            title: "Different Title",
            subtitle: "Different Sub",
            startTime: "10:00",
            endTime: "18:00",
            timeSpent: "7:00",
            isActive: true
        )
        
        // Même ID = même identité
        #expect(entry1.id == entry2.id)
    }
    
    @Test("Two TimeEntries with different IDs are different")
    func testDifferentIds() {
        let entry1 = TimeEntry(
            id: "1",
            title: "A",
            subtitle: "B",
            startTime: nil,
            endTime: nil,
            timeSpent: "0:00",
            isActive: false
        )
        
        let entry2 = TimeEntry(
            id: "2",
            title: "A",
            subtitle: "B",
            startTime: nil,
            endTime: nil,
            timeSpent: "0:00",
            isActive: false
        )
        
        #expect(entry1.id != entry2.id)
    }
}
