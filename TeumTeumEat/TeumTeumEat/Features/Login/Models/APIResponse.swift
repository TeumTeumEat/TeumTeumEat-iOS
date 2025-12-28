//
//  APIResponse.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let code: String
    let message: String
    let details: String?
    let data: T?
}
