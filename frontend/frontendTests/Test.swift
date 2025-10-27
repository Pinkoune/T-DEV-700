import Testing
@testable import frontend

@Suite("Basic Import Tests")
struct BasicTests {
    
    @Test("Can create TimeEntry")
    func testTimeEntryCreation() {
        let entry = TimeEntry(
            id: "1",
            title: "Test",
            subtitle: "Test",
            startTime: "9:00",
            endTime: nil,
            timeSpent: "1:00",
            isActive: true
        )
        
        #expect(entry.id == "1")
    }
}
