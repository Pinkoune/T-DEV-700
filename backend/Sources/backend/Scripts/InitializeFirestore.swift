import Vapor

// Fonction asynchrone pour initialiser Firestore en ajoutant des documents de test.
// Cela créé automatiquement les collections si elles n'existent pas.
// Appel de cette fonction temporaire depuis configure.swift
// A supprimer après le test
// FIXME: Cette fonction utilise Firebase SDK - à réimplanter avec HTTP client

public func initializeFirestore(app: Application) async throws {
	// TODO: Réimplanter avec Firebase REST API
	app.logger.info("Firebase initialization with REST API not yet implemented")
	return

	/*
	let firestore = app.firestore

	// Création d'un utilisateur test
	let user = User(
		firstName: "TestFirstName",
		lastName: "TestLastName",
		email: "test@email.com",
		phone: "0123456789",
		role: "employee",
		department: "IT",
		position: "Développeur"
	)
	
	let userDocRef = try await firestore.collection("users").addDocument(data: [
		"firstName": user.firstName,
		"lastName": user.lastName,
		"email": user.email,
		"phone": user.phone,
		"role": user.role,
		"department": user.department ?? "",
		"position": user.position ?? "",
		"hireDate": user.hireDate ?? Date(),
		"createdAt": user.createdAt,
		"updatedAt": user.updatedAt,
		"isActive": user.isActive,
		"weeklyHoursTarget": user.weeklyHoursTarget
	])
	print("Utilisateur de test créé avec ID: \(userDocRef.documentID)")

	// Création d'une équipe de test
	let team = Team(
		name: "Equipe Test",
		description: "Description de l'équipe test",
		managerId: userDocRef.documentID // L'utilisateur créé devient manager
	)
	
	let teamDocRef = try await firestore.collection("teams").addDocument(data: [
		"name": team.name,
		"description": team.description,
		"members": team.members,
		"managerId": team.managerId,
		"color": team.color,
		"createdAt": team.createdAt,
		"updatedAt": team.updatedAt,
		"isActive": team.isActive
	])
	print("Équipe de test créée avec ID: \(teamDocRef.documentID)")

	// Création d'une entrée de temps de test
	var timeEntry = TimeEntry(
		userId: userDocRef.documentID,
		notes: "Journée de test"
	)
	// Simuler une fin de journée
	timeEntry.clockOut()
	
	let timeEntryDocRef = try await firestore.collection("timeEntries").addDocument(data: [
		"userId": timeEntry.userId,
		"arrival": timeEntry.arrival,
		"departure": timeEntry.departure ?? NSNull(),
		"hoursWorked": timeEntry.hoursWorked ?? NSNull(),
		"status": timeEntry.status,
		"notes": timeEntry.notes ?? "",
		"createdAt": timeEntry.createdAt,
		"updatedAt": timeEntry.updatedAt
	])
	print("Entrée de temps de test créée avec ID: \(timeEntryDocRef.documentID)")

	// Création d'une performance de test
	let performance = Performance(
		userId: userDocRef.documentID,
		period: "week",
		index: 95.0
	)
	
	let performanceDocRef = try await firestore.collection("performances").addDocument(data: [
		"userId": performance.userId,
		"period": performance.period,
		"index": performance.index,
		"createdAt": performance.createdAt,
		"updatedAt": performance.updatedAt
	])
	print("Performance de test créée avec ID: \(performanceDocRef.documentID)")

	*/
}
