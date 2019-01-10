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
    
    static let entity = "tokens"
    
    var id: Int?
    var token: String
    var userId: User.ID
    
    init(token: String, userId: User.ID) {
        self.token = token
        self.userId = userId
    }
    
    static func createToken(forUser user: User) throws -> Token {
        let tokenString = Helpers.randomToken(withLength: 60)
        let newToken = try Token(token: tokenString, userId: user.requireID())
        return newToken
    }
    
}

class Helpers {
    // credit for this randomToken method: https://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
    class func randomToken(withLength length: Int) -> String {
        let allowedChars = "$!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let allowedCharsCount = UInt32(allowedChars.count)
        var randomString = ""
        for _ in 0..<length {
            let randomNumber = Int(arc4random_uniform(allowedCharsCount))
            let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNumber)
            let newCharacter = allowedChars[randomIndex]
            randomString += String(newCharacter)
        }
        return randomString
    }
}


extension Token: Migration { }

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
