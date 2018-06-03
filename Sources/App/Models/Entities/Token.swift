//
//  Token.swift
//  App
//
//  Created by Hadi Sharghi on 3/6/1397 .
//

import Vapor
import FluentMySQL
import Authentication

final class Token: MySQLModel {
    var id: Int?
    var token: String
    var userId: User.ID
    
    init(token: String, userId: User.ID) {
        self.token = token
        self.userId = userId
    }
    
    
}


extension Token {
    var user: Parent<Token, User> {
        return parent(\.userId)
    }
}

extension Token: BearerAuthenticatable {
    static var tokenKey: WritableKeyPath<Token, String> { return \Token.token }
}

extension Token: Authentication.Token {
    static var userIDKey: WritableKeyPath<Token, User.ID> { return \Token.userId } // 1
    typealias UserType = User // 2
    typealias UserIDType = User.ID //3
}
