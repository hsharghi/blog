//
//  Common.swift
//  App
//
//  Created by Hadi Sharghi on 8/31/18.
//

import FluentMySQL
import Vapor
import Pagination



struct PaginatedResponse<M: Content>: Content {
    var data: [M]
    var page: PageInfo
    
    init(data: [M], pageInfo: PageInfo) {
        self.data = data
        self.page = pageInfo
    }
    
}
    
