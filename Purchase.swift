//
//  Purchase.swift
//  Firesale Pre-Alpha
//
//  Created by Christian Cournoyer on 6/20/25.
//


import FirebaseFirestore

struct Purchase: Identifiable, Codable {
    @DocumentID var id: String?
    let itemId: String
    let userId: String
    let storeId: String
    let createdAt: Timestamp
    let pickupBy: Timestamp
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case id
        case itemId
        case userId
        case storeId
        case createdAt
        case pickupBy
        case quantity
    }
}