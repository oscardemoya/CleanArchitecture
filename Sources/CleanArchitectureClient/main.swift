import CleanArchitecture

public protocol AuthRepository {
    func logIn(email: String, password: String) async throws -> User
}

public protocol ProfileRepository {
    func profile(for user: User) async throws -> Profile
}

public struct User: Identifiable {
    public var id: String
    public var email: String?
    public var profile: Profile?
    
    public init(id: String, email: String? = nil) {
        self.id = id
        self.email = email
    }
}

public struct Profile: Identifiable {
    public var id: String
    public var firstName: String = ""
    public var lastName: String = ""
    
    public init(id: String, firstName: String, lastName: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }
}

@UseCase
struct EmailLogin {
    let authRepository: AuthRepository
    let profileRepository: ProfileRepository
    
    func execute(email: String, password: String) async throws -> User {
        var user = try await authRepository.logIn(email: email, password: password)
        user.profile = try await profileRepository.profile(for: user)
        return user
    }
}
