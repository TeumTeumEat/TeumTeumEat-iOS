//
//  APIResponse.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import Foundation

public struct APIResponse<T: Decodable>: Decodable {
    public let code: String
    public let message: String
    public let details: String?
    public let data: T?
}
