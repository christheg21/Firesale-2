//
//  Reservation.swift
//  Firesale Pre-Alpha
//
//  Created by Christian Cournoyer on 6/20/25.
//


import FirebaseFirestore

struct Reservation: Identifiable, Codable {
    @DocumentID var id: String?
    let itemId: String
    let userId: String
    let storeId: String
    let status: String // pending, accepted, declined
    let createdAt: Timestamp
    let expiresAt: Timestamp
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case id
        case itemId
        case userId
        case storeId
        case status
        case createdAt
        case expiresAt
        case quantity
    }
}