import Vapor
import Crypto
import Fakery

extension Collection where Index == Int {
    
    /**
     Picks a random element of the collection.
     
     - returns: A random element of the collection.
     */
    private func random(max: UInt32) -> Int {
        #if os(Linux)
        seedRandom()
        return Int((random() % max))
        #else
        return Int(arc4random_uniform(UInt32(max)))
        #endif
    }
    
    func randomElement() -> Iterator.Element? {
        let index = random(max: UInt32(endIndex))
        return isEmpty ? nil : self[index]
    }
    
}


/// Controls basic CRUD operations on `User`s.
final class SeederController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let seeder = router.grouped("seed")
        seeder.get("users", Int.parameter, use: seedUser)
        seeder.get("posts", Int.parameter, use: seedPost)
        seeder.get("comment", Int.parameter, use: seedComment)
    }
    
    func seedUser(_ req: Request) throws -> HTTPStatus {
        let numUsers = try req.parameters.next(Int.self)
        let faker = Faker(locale: "en")
        let password = "123456"
        let hasher = try req.make(BCryptDigest.self)
        let hashedPassword = try hasher.hash(password, cost: 4)
        for _ in 0..<numUsers {
            let user = User(username: faker.internet.username(), email: faker.internet.email(), password: hashedPassword)
            _ = user.save(on: req)
        }
        return HTTPStatus.ok
    }
    
    func seedPost(_ req: Request) throws -> HTTPStatus {
        let numPosts = try req.parameters.next(Int.self)
        let faker = Faker(locale: "en")
        _ = User.query(on: req).all().map { (users)  in
//            let userIds = users.map { return $0.id! }
            for _ in 0..<numPosts {
                if let userId = users.random?.id {
                    let post = Post(
                        title: faker.lorem.words(amount: faker.number.randomInt(min: 2, max: 6)),
                        body: faker.lorem.paragraph(sentencesAmount: faker.number.randomInt(min: 1, max: 8)),
                        userId: userId)
                    _ = post.save(on: req).map { post in
                        let date = faker.date.between(from: faker.date.backward(years: 3), to: Date())
                        post.createdAt = date
                        _ = post.save(on: req)
                    }
                }
            }
        }
        return HTTPStatus.ok
    }
    
    func seedComment(_ req: Request) throws -> HTTPStatus {
        let maxNumComments = try req.parameters.next(Int.self)
        let faker = Faker(locale: "en")
        let users = User.query(on: req).all()
        let posts = Post.query(on: req).all()
        _ = map(to: Void.self, users, posts) { users, posts in
            posts.forEach({ (post) in
                let numOfComments = faker.number.randomInt(min: 0, max: maxNumComments+1)
                for _ in 0..<numOfComments {
                    if let userId = users.random?.id {
                        let comment = Comment(postId: post.id!,
                                              userId: userId,
                                              body: faker.lorem.paragraph(sentencesAmount: faker.number.randomInt(min: 1, max: 8)))
                        _ = comment.save(on: req).map { comment in
                            let date = faker.date.between(from: post.createdAt!, to: Date())
                            comment.createdAt = date
                            _ = comment.save(on: req)
                        }
                    }
                }
            })
        }
        return HTTPStatus.ok
    }
    
}













