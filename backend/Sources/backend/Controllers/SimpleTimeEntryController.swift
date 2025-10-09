import Vapor

struct SimpleTimeEntryController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let timeEntries = routes.grouped("api", "timeentries")
        
        // Routes CRUD de base
        timeEntries.get(use: getAllTimeEntries)
        timeEntries.post(use: createTimeEntry)
        timeEntries.group(":timeEntryID") { timeEntry in
            timeEntry.get(use: getTimeEntry)
            timeEntry.put(use: updateTimeEntry)
            timeEntry.delete(use: deleteTimeEntry)
        }
        
        // Routes de pointage
        timeEntries.post("clock-in", use: clockIn)
        timeEntries.post("clock-out", ":timeEntryID", use: clockOut)
        timeEntries.get("active", ":userID", use: getActiveTimeEntry)
        
        // Routes de filtrage
        timeEntries.get("by-user", ":userID", use: getTimeEntriesByUser)
    }
    
    // Opérations CRUD
    
    func getAllTimeEntries(req: Request) async throws -> [TimeEntryResponse] {
        let timeEntries = await MockDataService.shared.getAllTimeEntries()
        return timeEntries.map { TimeEntryResponse(from: $0) }
    }
    
    func createTimeEntry(req: Request) async throws -> TimeEntryResponse {
        let timeEntryData = try req.content.decode(CreateTimeEntryRequest.self)
        
        let timeEntry = TimeEntry(
            userId: timeEntryData.userId,
            notes: timeEntryData.notes
        )
        
        let createdTimeEntry = await MockDataService.shared.createTimeEntry(timeEntry)
        return TimeEntryResponse(from: createdTimeEntry)
    }
    
    func getTimeEntry(req: Request) async throws -> TimeEntryResponse {
        guard let timeEntryID = req.parameters.get("timeEntryID") else {
            throw Abort(.badRequest, reason: "ID entrée de temps manquant")
        }
        
        guard let timeEntry = await MockDataService.shared.getTimeEntry(id: timeEntryID) else {
            throw Abort(.notFound, reason: "Entrée de temps non trouvée")
        }
        
        return TimeEntryResponse(from: timeEntry)
    }
    
    func updateTimeEntry(req: Request) async throws -> TimeEntryResponse {
        guard let timeEntryID = req.parameters.get("timeEntryID") else {
            throw Abort(.badRequest, reason: "ID entrée de temps manquant")
        }
        
        guard let existingTimeEntry = await MockDataService.shared.getTimeEntry(id: timeEntryID) else {
            throw Abort(.notFound, reason: "Entrée de temps non trouvée")
        }
        
        let updateData = try req.content.decode(UpdateTimeEntryRequest.self)
        
        var updatedTimeEntry = existingTimeEntry
        if let arrival = updateData.arrival { updatedTimeEntry.arrival = arrival }
        if let departure = updateData.departure { 
            updatedTimeEntry.departure = departure
            updatedTimeEntry.hoursWorked = updatedTimeEntry.calculatedHours
        }
        if let notes = updateData.notes { updatedTimeEntry.notes = notes }
        if let status = updateData.status { updatedTimeEntry.status = status }
        
        guard let finalTimeEntry = await MockDataService.shared.updateTimeEntry(id: timeEntryID, updatedTimeEntry) else {
            throw Abort(.internalServerError, reason: "Erreur lors de la mise à jour")
        }
        
        return TimeEntryResponse(from: finalTimeEntry)
    }
    
    func deleteTimeEntry(req: Request) async throws -> HTTPStatus {
        guard let timeEntryID = req.parameters.get("timeEntryID") else {
            throw Abort(.badRequest, reason: "ID entrée de temps manquant")
        }
        
        guard await MockDataService.shared.deleteTimeEntry(id: timeEntryID) else {
            throw Abort(.notFound, reason: "Entrée de temps non trouvée")
        }
        
        return .noContent
    }
    
    // Opérations du temps d'entrée et sortie
    
    func clockIn(req: Request) async throws -> TimeEntryResponse {
        let clockInData = try req.content.decode(ClockInRequest.self)
        
        // Vérifier qu'il n'y a pas déjà une entrée active
        if await MockDataService.shared.getActiveTimeEntry(userId: clockInData.userId) != nil {
            throw Abort(.conflict, reason: "Vous avez déjà pointé votre arrivée")
        }
        
        let timeEntry = TimeEntry(
            userId: clockInData.userId,
            notes: clockInData.notes
        )
        
        let createdTimeEntry = await MockDataService.shared.createTimeEntry(timeEntry)
        return TimeEntryResponse(from: createdTimeEntry)
    }
    
    func clockOut(req: Request) async throws -> TimeEntryResponse {
        guard let timeEntryID = req.parameters.get("timeEntryID") else {
            throw Abort(.badRequest, reason: "ID entrée de temps manquant")
        }
        
        guard var timeEntry = await MockDataService.shared.getTimeEntry(id: timeEntryID) else {
            throw Abort(.notFound, reason: "Entrée de temps non trouvée")
        }
        
        if timeEntry.status != "active" {
            throw Abort(.badRequest, reason: "Cette entrée de temps n'est pas active")
        }
        
        timeEntry.clockOut()
        
        guard let updatedTimeEntry = await MockDataService.shared.updateTimeEntry(id: timeEntryID, timeEntry) else {
            throw Abort(.internalServerError, reason: "Erreur lors du pointage de sortie")
        }
        
        return TimeEntryResponse(from: updatedTimeEntry)
    }
    
    func getActiveTimeEntry(req: Request) async throws -> ActiveTimeEntryResponse {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        if let timeEntry = await MockDataService.shared.getActiveTimeEntry(userId: userID) {
            return ActiveTimeEntryResponse(
                hasActiveEntry: true,
                timeEntry: TimeEntryResponse(from: timeEntry)
            )
        } else {
            return ActiveTimeEntryResponse(
                hasActiveEntry: false,
                timeEntry: nil
            )
        }
    }
    
    func getTimeEntriesByUser(req: Request) async throws -> [TimeEntryResponse] {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let timeEntries = await MockDataService.shared.getTimeEntriesByUser(userId: userID)
        return timeEntries.map { TimeEntryResponse(from: $0) }
    }
}
