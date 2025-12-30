//
//  UpdateUserNameRequest.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

struct EmptyData: Decodable {}


struct UpdateUserNameRequest: Encodable {
    let name: String
}
