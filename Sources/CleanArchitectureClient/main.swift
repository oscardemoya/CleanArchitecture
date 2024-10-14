import CleanArchitecture
import Foundation

// MARK: #MakeRepository

struct RepositoryFactory {
    #MakeRepository<AuthRepository>()
    #MakeRepository<ProfileRepository>()
}

// MARK: @UseCase

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

// MARK: #MakeUseCase

struct UseCaseFactory {
    #MakeUseCase<AuthRepository & ProfileRepository>(FetchCurrentUserUseCase)
}

// MARK: @AppService

@AppService
final class ProfileService: @unchecked Sendable, ObservableObject {
    private var fetchCurrentUserUseCase: FetchCurrentUserUseCase
}

// MARK: - Sample Source Code

public struct FetchCurrentUserFactory {
    public static func makeUseCase(authRepository: AuthRepository, profileRepository: ProfileRepository) -> FetchCurrentUserUseCase {
        FetchCurrentUserDefaultUseCase(authRepository: authRepository, profileRepository: profileRepository)
    }
}

class FetchCurrentUserDefaultUseCase: FetchCurrentUserUseCase {
    let authRepository: AuthRepository
    let profileRepository: ProfileRepository
    let useCase: FetchCurrentUser

    init(authRepository: AuthRepository, profileRepository: ProfileRepository) {
        self.authRepository = authRepository
        self.profileRepository = profileRepository
        self.useCase = FetchCurrentUser(authRepository: authRepository, profileRepository: profileRepository)
    }

    func execute() async throws -> User {
        try await useCase.execute()
    }
}

struct FetchCurrentUser {
    let authRepository: AuthRepository
    let profileRepository: ProfileRepository
    
    func execute() async throws -> User {
        return User(id: "id")
    }
}

public protocol FetchCurrentUserUseCase {
    func execute() async throws -> User
}

final class DefaultAuthRepository: AuthRepository {
    func logIn(email: String, password: String) async throws -> User {
        User(id: email)
    }
}

final class DefaultProfileRepository: ProfileRepository {
    func profile(for user: User) async throws -> Profile {
        Profile(id: user.id)
    }
}

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
    public var firstName: String?
    public var lastName: String?
    
    public init(id: String, firstName: String? = nil, lastName: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }
}
