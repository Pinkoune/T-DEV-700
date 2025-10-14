import Vapor
import FirebaseFirestore

struct TimeEntryController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let timeEntries = routes.grouped("api", "timeentries")
        
        // Routes protégées par JWT
        let protected = timeEntries.grouped(JWTAuthMiddleware())
        
        // Routes CRUD
        protected.get(use: getAllTimeEntries)
        protected.post(use: createTimeEntry)
        protected.group(":timeEntryID") { timeEntry in
            timeEntry.get(use: getTimeEntry)
            timeEntry.put(use: updateTimeEntry)
            timeEntry.delete(use: deleteTimeEntry)
        }
        
        // Routes de pointage
        protected.post("clock-in", use: clockIn)
        protected.post("clock-out", ":timeEntryID", use: clockOut)
        protected.get("active", ":userID", use: getActiveTimeEntry)
        
        // Routes de filtrage et statistiques
        protected.get("by-user", ":userID", use: getTimeEntriesByUser)
        protected.get("by-date", use: getTimeEntriesByDate)
        protected.get("overtime", use: getOvertimeEntries)
        protected.get("stats", ":userID", use: getUserTimeStats)
        protected.get("daily-summary", ":userID", use: getDailySummary)
    }
    
    
    // Operations CRUD
    
    /// GET /api/timeentries - Récupére toutes les entrées de temps
    func getAllTimeEntries(req: Request) async throws -> [TimeEntryResponse] {
        let firestore = req.application.firestore
        let limit = req.query["limit"] ?? 50
        
        do {
            let snapshot = try await firestore.collection("timeEntries")
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            var timeEntries: [TimeEntryResponse] = []
            for document in snapshot.documents {
                if let timeEntry = try? document.data(as: TimeEntry.self) {
                    var timeEntryWithId = timeEntry
                    timeEntryWithId.id = document.documentID
                    timeEntries.append(TimeEntryResponse(from: timeEntryWithId))
                }
            }
            
            return timeEntries
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des entrées de temps: \(error.localizedDescription)")
        }
    }
    
    /// POST /api/timeentries - Crée une nouvelle entrée de temps
    func createTimeEntry(req: Request) async throws -> TimeEntryResponse {
        try TimeEntry.validate(content: req)
        let timeEntryData = try req.content.decode(CreateTimeEntryRequest.self)
        
        let timeEntry = TimeEntry(
            userId: timeEntryData.userId,
            notes: timeEntryData.notes
        )
        
        let firestore = req.application.firestore
        
        do {
            // Vérifie que l'utilisateur existe
            let userDoc = try await firestore.collection("users").document(timeEntryData.userId).getDocument()
            guard userDoc.exists else {
                throw Abort(.badRequest, reason: "Utilisateur non trouvé")
            }
            
            // Vérifie qu'il n'y a pas déjà une entrée active pour cet utilisateur
            let activeEntries = try await firestore.collection("timeEntries")
                .whereField("userId", isEqualTo: timeEntryData.userId)
                .whereField("status", isEqualTo: "active")
                .getDocuments()
            
            if !activeEntries.documents.isEmpty {
                throw Abort(.conflict, reason: "L'utilisateur a déjà une entrée de temps active")
            }
            
            let docRef = try await firestore.collection("timeEntries").addDocument(data: [
                "userId": timeEntry.userId,
                "arrival": timeEntry.arrival,
                "departure": NSNull(),
                "hoursWorked": NSNull(),
                "status": timeEntry.status,
                "notes": timeEntry.notes ?? "",
                "createdAt": timeEntry.createdAt,
                "updatedAt": timeEntry.updatedAt
            ])
            
            var createdTimeEntry = timeEntry
            createdTimeEntry.id = docRef.documentID
            
            return TimeEntryResponse(from: createdTimeEntry)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la création de l'entrée de temps: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/timeentries/:timeEntryID - Récupére une entrée de temps spécifique
    func getTimeEntry(req: Request) async throws -> TimeEntryResponse {
        guard let timeEntryID = req.parameters.get("timeEntryID") else {
            throw Abort(.badRequest, reason: "ID entrée de temps manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let document = try await firestore.collection("timeEntries").document(timeEntryID).getDocument()
            
            guard document.exists else {
                throw Abort(.notFound, reason: "Entrée de temps non trouvée")
            }
            
            guard var timeEntry = try? document.data(as: TimeEntry.self) else {
                throw Abort(.internalServerError, reason: "Erreur lors du décodage de l'entrée de temps")
            }
            
            timeEntry.id = document.documentID
            return TimeEntryResponse(from: timeEntry)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération de l'entrée de temps: \(error.localizedDescription)")
        }
    }
    
    /// PUT /api/timeentries/:timeEntryID - Met à jour une entrée de temps
    func updateTimeEntry(req: Request) async throws -> TimeEntryResponse {
        guard let timeEntryID = req.parameters.get("timeEntryID") else {
            throw Abort(.badRequest, reason: "ID entrée de temps manquant")
        }
        
        let updateData = try req.content.decode(UpdateTimeEntryRequest.self)
        let firestore = req.application.firestore
        
        do {
            let docRef = firestore.collection("timeEntries").document(timeEntryID)
            let document = try await docRef.getDocument()
            
            guard document.exists else {
                throw Abort(.notFound, reason: "Entrée de temps non trouvée")
            }
            
            guard var existingTimeEntry = try? document.data(as: TimeEntry.self) else {
                throw Abort(.internalServerError, reason: "Erreur lors du décodage de l'entrée de temps")
            }
            
            // Mise à jour des champs modifiés
            var updateFields: [String: Any] = ["updatedAt": Date()]
            
            if let arrival = updateData.arrival {
                existingTimeEntry.arrival = arrival
                updateFields["arrival"] = arrival
            }
            if let departure = updateData.departure {
                existingTimeEntry.departure = departure
                updateFields["departure"] = departure
                // Recalcule les heures travaillées
                existingTimeEntry.hoursWorked = existingTimeEntry.calculatedHours
                updateFields["hoursWorked"] = existingTimeEntry.hoursWorked
            }
            if let notes = updateData.notes {
                existingTimeEntry.notes = notes
                updateFields["notes"] = notes
            }
            if let status = updateData.status {
                existingTimeEntry.status = status
                updateFields["status"] = status
            }
            
            try await docRef.updateData(updateFields)
            
            existingTimeEntry.id = timeEntryID
            existingTimeEntry.updatedAt = Date()
            
            return TimeEntryResponse(from: existingTimeEntry)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la mise à jour de l'entrée de temps: \(error.localizedDescription)")
        }
    }
    
    /// DELETE /api/timeentries/:timeEntryID - Supprime une entrée de temps
    func deleteTimeEntry(req: Request) async throws -> HTTPStatus {
        guard let timeEntryID = req.parameters.get("timeEntryID") else {
            throw Abort(.badRequest, reason: "ID entrée de temps manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let docRef = firestore.collection("timeEntries").document(timeEntryID)
            let document = try await docRef.getDocument()
            
            guard document.exists else {
                throw Abort(.notFound, reason: "Entrée de temps non trouvée")
            }
            
            // Marqueur pour annuler au lieu de supprimer
            try await docRef.updateData([
                "status": "cancelled",
                "updatedAt": Date()
            ])
            
            return .noContent
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la suppression de l'entrée de temps: \(error.localizedDescription)")
        }
    }
    
    // Opérations du temps d'entrée et sortie
    
    /// POST /api/timeentries/clock-in - Pointer l'arrivée
    func clockIn(req: Request) async throws -> TimeEntryResponse {
        let clockInData = try req.content.decode(ClockInRequest.self)
        
        let firestore = req.application.firestore
        
        do {
            // Vérifie que l'utilisateur existe
            let userDoc = try await firestore.collection("users").document(clockInData.userId).getDocument()
            guard userDoc.exists else {
                throw Abort(.badRequest, reason: "Utilisateur non trouvé")
            }
            
            // Vérifie qu'il n'y a pas déjà une entrée active
            let activeEntries = try await firestore.collection("timeEntries")
                .whereField("userId", isEqualTo: clockInData.userId)
                .whereField("status", isEqualTo: "active")
                .getDocuments()
            
            if !activeEntries.documents.isEmpty {
                throw Abort(.conflict, reason: "Vous avez déjà pointé votre arrivée")
            }
            
            let timeEntry = TimeEntry(
                userId: clockInData.userId,
                notes: clockInData.notes
            )
            
            let docRef = try await firestore.collection("timeEntries").addDocument(data: [
                "userId": timeEntry.userId,
                "arrival": timeEntry.arrival,
                "departure": NSNull(),
                "hoursWorked": NSNull(),
                "status": timeEntry.status,
                "notes": timeEntry.notes ?? "",
                "createdAt": timeEntry.createdAt,
                "updatedAt": timeEntry.updatedAt
            ])
            
            var createdTimeEntry = timeEntry
            createdTimeEntry.id = docRef.documentID
            
            return TimeEntryResponse(from: createdTimeEntry)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors du pointage d'arrivée: \(error.localizedDescription)")
        }
    }
    
    /// POST /api/timeentries/clock-out/:timeEntryID - Pointer la sortie
    func clockOut(req: Request) async throws -> TimeEntryResponse {
        guard let timeEntryID = req.parameters.get("timeEntryID") else {
            throw Abort(.badRequest, reason: "ID entrée de temps manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let docRef = firestore.collection("timeEntries").document(timeEntryID)
            let document = try await docRef.getDocument()
            
            guard document.exists else {
                throw Abort(.notFound, reason: "Entrée de temps non trouvée")
            }
            
            guard var timeEntry = try? document.data(as: TimeEntry.self) else {
                throw Abort(.internalServerError, reason: "Erreur lors du décodage de l'entrée de temps")
            }
            
            // Vérifie que l'entrée est active
            if timeEntry.status != "active" {
                throw Abort(.badRequest, reason: "Cette entrée de temps n'est pas active")
            }
            
            // Pointe la sortie
            timeEntry.clockOut()
            
            try await docRef.updateData([
                "departure": timeEntry.departure ?? Date(),
                "hoursWorked": timeEntry.hoursWorked ?? 0,
                "status": timeEntry.status,
                "updatedAt": timeEntry.updatedAt
            ])
            
            timeEntry.id = timeEntryID
            
            return TimeEntryResponse(from: timeEntry)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors du pointage de sortie: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/timeentries/active/:userID - Récupére l'entrée de temps active d'un utilisateur
    func getActiveTimeEntry(req: Request) async throws -> ActiveTimeEntryResponse {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("timeEntries")
                .whereField("userId", isEqualTo: userID)
                .whereField("status", isEqualTo: "active")
                .limit(to: 1)
                .getDocuments()
            
            if let document = snapshot.documents.first {
                guard var timeEntry = try? document.data(as: TimeEntry.self) else {
                    throw Abort(.internalServerError, reason: "Erreur lors du décodage de l'entrée de temps")
                }
                
                timeEntry.id = document.documentID
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
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération de l'entrée active: \(error.localizedDescription)")
        }
    }
    
    // Routes pour les statistiques et les filtres
    
    /// GET /api/timeentries/by-user/:userID - Entrées de temps par utilisateur
    func getTimeEntriesByUser(req: Request) async throws -> [TimeEntryResponse] {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let limit = req.query["limit"] ?? 20
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("timeEntries")
                .whereField("userId", isEqualTo: userID)
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            var timeEntries: [TimeEntryResponse] = []
            for document in snapshot.documents {
                if let timeEntry = try? document.data(as: TimeEntry.self) {
                    var timeEntryWithId = timeEntry
                    timeEntryWithId.id = document.documentID
                    timeEntries.append(TimeEntryResponse(from: timeEntryWithId))
                }
            }
            
            return timeEntries
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des entrées de temps: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/timeentries/by-date?date=DD-MM-YYYY - Entrées de temps par date
    func getTimeEntriesByDate(req: Request) async throws -> [TimeEntryResponse] {
        guard let dateString = req.query["date"] as String? else {
            throw Abort(.badRequest, reason: "Date manquante (format: DD-MM-YYYY)")
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        guard let date = formatter.date(from: dateString) else {
            throw Abort(.badRequest, reason: "Format de date invalide (attendu: DD-MM-YYYY)")
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("timeEntries")
                .whereField("arrival", isGreaterThanOrEqualTo: startOfDay)
                .whereField("arrival", isLessThan: endOfDay)
                .order(by: "arrival")
                .getDocuments()
            
            var timeEntries: [TimeEntryResponse] = []
            for document in snapshot.documents {
                if let timeEntry = try? document.data(as: TimeEntry.self) {
                    var timeEntryWithId = timeEntry
                    timeEntryWithId.id = document.documentID
                    timeEntries.append(TimeEntryResponse(from: timeEntryWithId))
                }
            }
            
            return timeEntries
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des entrées par date: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/timeentries/overtime - Entrées avec heures supplémentaires
    func getOvertimeEntries(req: Request) async throws -> [TimeEntryResponse] {
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("timeEntries")
                .whereField("status", isEqualTo: "completed")
                .whereField("hoursWorked", isGreaterThan: 8.0)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            var timeEntries: [TimeEntryResponse] = []
            for document in snapshot.documents {
                if let timeEntry = try? document.data(as: TimeEntry.self) {
                    var timeEntryWithId = timeEntry
                    timeEntryWithId.id = document.documentID
                    timeEntries.append(TimeEntryResponse(from: timeEntryWithId))
                }
            }
            
            return timeEntries
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la récupération des heures supplémentaires: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/timeentries/stats/:userID - Statistiques de temps d'un utilisateur
    func getUserTimeStats(req: Request) async throws -> UserTimeStatsResponse {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let firestore = req.application.firestore
        
        do {
            // Récupére toutes les entrées complétées de l'utilisateur
            let snapshot = try await firestore.collection("timeEntries")
                .whereField("userId", isEqualTo: userID)
                .whereField("status", isEqualTo: "completed")
                .getDocuments()
            
            var totalHours = 0.0
            var overtimeHours = 0.0
            var totalDays = 0
            var overtimeDays = 0
            
            for document in snapshot.documents {
                if let timeEntry = try? document.data(as: TimeEntry.self) {
                    totalHours += timeEntry.hoursWorked ?? 0
                    totalDays += 1
                    
                    if timeEntry.isOvertime {
                        overtimeHours += timeEntry.overtimeHours
                        overtimeDays += 1
                    }
                }
            }
            
            let averageHoursPerDay = totalDays > 0 ? totalHours / Double(totalDays) : 0.0
            
            return UserTimeStatsResponse(
                userId: userID,
                totalHours: totalHours,
                totalDays: totalDays,
                averageHoursPerDay: averageHoursPerDay,
                overtimeHours: overtimeHours,
                overtimeDays: overtimeDays
            )
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors du calcul des statistiques: \(error.localizedDescription)")
        }
    }
    
    /// GET /api/timeentries/daily-summary/:userID?date=DD-MM-YYYY - Résumé quotidien
    func getDailySummary(req: Request) async throws -> DailySummaryResponse {
        guard let userID = req.parameters.get("userID") else {
            throw Abort(.badRequest, reason: "ID utilisateur manquant")
        }
        
        let dateString = req.query["date"] as String? ?? {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MM-yyyy"
            return formatter.string(from: Date())
        }()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        guard let date = formatter.date(from: dateString) else {
            throw Abort(.badRequest, reason: "Format de date invalide")
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let firestore = req.application.firestore
        
        do {
            let snapshot = try await firestore.collection("timeEntries")
                .whereField("userId", isEqualTo: userID)
                .whereField("arrival", isGreaterThanOrEqualTo: startOfDay)
                .whereField("arrival", isLessThan: endOfDay)
                .getDocuments()
            
            var entries: [TimeEntryResponse] = []
            var totalHours = 0.0
            var isCurrentlyWorking = false
            
            for document in snapshot.documents {
                if let timeEntry = try? document.data(as: TimeEntry.self) {
                    var timeEntryWithId = timeEntry
                    timeEntryWithId.id = document.documentID
                    entries.append(TimeEntryResponse(from: timeEntryWithId))
                    
                    if timeEntry.status == "completed" {
                        totalHours += timeEntry.hoursWorked ?? 0
                    } else if timeEntry.status == "active" {
                        isCurrentlyWorking = true
                        totalHours += timeEntry.calculatedHours
                    }
                }
            }
            
            return DailySummaryResponse(
                date: dateString,
                userId: userID,
                entries: entries,
                totalHours: totalHours,
                isCurrentlyWorking: isCurrentlyWorking,
                isOvertime: totalHours > 8.0
            )
        } catch {
            throw Abort(.internalServerError, reason: "Erreur lors de la génération du résumé quotidien: \(error.localizedDescription)")
        }
    }

// Modèles de réponses et requêtes

struct CreateTimeEntryRequest: Content, Validatable {
    let userId: String
    let notes: String?
    
    static func validations(_ validations: inout Validations) {
        validations.add("userId", as: String.self, is: !.empty)
    }
}

struct UpdateTimeEntryRequest: Content {
    let arrival: Date?
    let departure: Date?
    let notes: String?
    let status: String?
}

struct ClockInRequest: Content, Validatable {
    let userId: String
    let notes: String?
    
    static func validations(_ validations: inout Validations) {
        validations.add("userId", as: String.self, is: !.empty)
    }
}

struct UserTimeStatsResponse: Content {
    let userId: String
    let totalHours: Double
    let totalDays: Int
    let averageHoursPerDay: Double
    let overtimeHours: Double
    let overtimeDays: Int
}

struct DailySummaryResponse: Content {
    let date: String
    let userId: String
    let entries: [TimeEntryResponse]
    let totalHours: Double
    let isCurrentlyWorking: Bool
    let isOvertime: Bool
}

struct ActiveTimeEntryResponse: Content {
    let hasActiveEntry: Bool
    let timeEntry: TimeEntryResponse?
}
}
