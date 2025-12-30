//
//  fileUpload.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

struct PresignedURLRequest: Encodable {
    let fileName: String
}

struct PresignedURLData: Decodable {
    let presignedUrl: String
    let key: String
}
