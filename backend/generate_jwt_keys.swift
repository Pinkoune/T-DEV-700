#!/usr/bin/env swift

import Foundation
import Crypto

// Générer une paire de clés Ed25519
let privateKey = Curve25519.Signing.PrivateKey()
let publicKey = privateKey.publicKey

// Extraire les données brutes
let privateKeyData = privateKey.rawRepresentation
let publicKeyData = publicKey.rawRepresentation

// Convertir en base64
let privateKeyBase64 = privateKeyData.base64EncodedString()
let publicKeyBase64 = publicKeyData.base64EncodedString()

print("Clés JWT générées:")
print("JWT_PRIVATE_KEY=\(privateKeyBase64)")
print("JWT_PUBLIC_KEY=\(publicKeyBase64)")
print("")
print("IMPORTANT : Stockez ces clés de manière sécurisée !")
print("Ne les commitez JAMAIS dans le repository !!")
