import CleanArchitecture
import Foundation

// MARK: General

@Injectable<AuthRepository>
struct LogoutUseCase {
    func execute() async throws {
    }
}

// MARK: DataSource
// @DataSourceFactory
// #MakeDataSource

@Injectable<RemoteDataSourceConfig>
struct DataSourceFactory {
    #MakeDataSource<any AuthDataSource, RemoteDataSourceConfig>()
    #MakeDataSource<any ProfileDataSource, RemoteDataSourceConfig>()
}

// MARK: Repository
// @RepositoryFactory
// #MakeRepository

@Injectable<DataSourceFactory>
struct RepositoryFactory {
    #MakeRepository<AuthRepository>()
    #MakeRepository<ProfileRepository>()
}

// MARK: UseCase

// @UseCaseFactory
// #MakeUseCase

@Injectable<RepositoryFactory>
struct UseCaseFactory {
    #MakeUseCase<AuthRepository, LoginUseCase>()
    #MakeUseCase<AuthRepository & ProfileRepository, FetchCurrentUserUseCase>()
}

// MARK: @AppService

@Observable
@AppService<UseCaseFactory>
final class DefaultAuthService: AuthService {
    private var loginUseCase: LoginUseCase
    
    func login(email: String, password: String) async throws -> User {
        User(id: email)
    }
}

@Observable
@AppService<UseCaseFactory>
final class DefaultProfileService: ProfileService {
    private var fetchCurrentUserUseCase: FetchCurrentUserUseCase
    
    func profile(for user: User) async throws -> Profile {
        Profile(id: user.id)
    }
}

// MARK: @ServiceContainer

@Observable
@ServiceContainer
final class ServiceContainer: ServiceProvider {
    let authService: AuthService
    let profileService: ProfileService
}

// MARK: - Sample Source Code

extension UseCaseFactory {
    init(environment: AppEnvironment = .current) {
        let dataSourceFactory = DataSourceFactory(environment: environment)
        let repositoryFactory = RepositoryFactory(dataSourceFactory: dataSourceFactory)
        self.init(repositoryFactory: repositoryFactory)
    }
}

extension DataSourceFactory {
    init(environment: AppEnvironment = .current) {
        let apiClient = APIClient()
        self.init(
            remoteDataSourceConfig: DefaultRemoteDataSourceConfig(apiClient: apiClient)
        )
    }
}

enum AppEnvironment {
    case staging
    case testing
    case production
    
    static var current: Self = .staging
}

protocol ServiceProvider {
    var authService: AuthService { get }
    var profileService: ProfileService { get }
}

protocol AuthService {
    func login(email: String, password: String) async throws -> User
}

protocol ProfileService {
    func profile(for user: User) async throws -> Profile
}

class LoginUseCase {
    let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    func execute() async throws -> User {
        try await authRepository.login(email: "", password: "")
    }
}

struct Login {
    let authRepository: AuthRepository
    
    func execute() async throws -> User {
        return User(id: "id")
    }
}

class FetchCurrentUserUseCase {
    let authRepository: AuthRepository
    let profileRepository: ProfileRepository

    init(authRepository: AuthRepository, profileRepository: ProfileRepository) {
        self.authRepository = authRepository
        self.profileRepository = profileRepository
    }

    func execute() async throws -> Profile {
        guard authRepository.isLoggedIn else {
            throw AuthError.notLoggedIn
        }
        return try await profileRepository.profile(for: User(id: "id"))
    }
}

enum AuthError: Error {
    case notLoggedIn
}

struct FetchCurrentUser {
    let authRepository: AuthRepository
    let profileRepository: ProfileRepository
    
    func execute() async throws -> User {
        return User(id: "id")
    }
}

@Injectable<AuthDataSource>
final class DefaultAuthRepository: AuthRepository {
    var isLoggedIn: Bool { true }
    
    func login(email: String, password: String) async throws -> User {
        User(id: email)
    }
    
    func logout() async throws {
    }
}

@Injectable<ProfileDataSource>
final class DefaultProfileRepository: ProfileRepository {
    func profile(for user: User) async throws -> Profile {
        Profile(id: user.id)
    }
}

protocol AuthRepository {
    var isLoggedIn: Bool { get }
    func login(email: String, password: String) async throws -> User
    func logout() async throws
}

protocol ProfileRepository {
    func profile(for user: User) async throws -> Profile
}

struct User: Identifiable {
    var id: String
    var email: String?
    var profile: Profile?
    
    init(id: String, email: String? = nil) {
        self.id = id
        self.email = email
    }
}

struct Profile: Identifiable {
    var id: String
    var firstName: String?
    var lastName: String?
    
    init(id: String, firstName: String? = nil, lastName: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }
}

struct UserData: Identifiable {
    var id: String
    var email: String?
    var profile: Profile?
    
    init(id: String, email: String? = nil) {
        self.id = id
        self.email = email
    }
}

struct ProfileData: Identifiable {
    var id: String
    var firstName: String?
    var lastName: String?
    
    init(id: String, firstName: String? = nil, lastName: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }
}

@ModelConvertible
struct LoginCredentialsData: Codable {
    @Convertible(key: "username")
    let email: String
    let password: String
}

struct LoginCredentials {
    let username: String
    let password: String
}

protocol AuthDataSource {
    func login(credentials: any Codable) async throws -> UserData
}

final class DefaultAuthDataSource: AuthDataSource, RemoteDataSource {
    let configuration: RemoteDataSourceConfig
    
    required init(configuration: RemoteDataSourceConfig) {
        self.configuration = configuration
    }
    
    func login(credentials: any Codable) async throws -> UserData {
        UserData(id: "id")
    }
}

protocol ProfileDataSource {
    func profile(id: String) async throws -> ProfileData
}

final class DefaultProfileDataSource: ProfileDataSource, RemoteDataSource {
    let configuration: RemoteDataSourceConfig
    
    required init(configuration: RemoteDataSourceConfig) {
        self.configuration = configuration
    }
    
    func profile(id: String) async throws -> ProfileData {
        ProfileData(id: "id")
    }
}

protocol ConfigurableDataSource {
    associatedtype Configuration
    
    var configuration: Configuration { get }
    init(configuration: Configuration)
}

// Remote Data Source

protocol RemoteDataSource: ConfigurableDataSource where Configuration == RemoteDataSourceConfig {
    var apiClient: APIClient { get }
}

extension RemoteDataSource {
    var apiClient: APIClient { configuration.apiClient }
}

protocol RemoteDataSourceConfig {
    var apiClient: APIClient { get }
}

struct DefaultRemoteDataSourceConfig: RemoteDataSourceConfig {
    let apiClient: APIClient
}

actor APIClient {}

// Secure Data Source

struct SecureDataSourceConfig {
    let keychain: KeychainManager
}

final class KeychainManager {}

// Local Data Source

protocol LocalDataSource: ConfigurableDataSource where Configuration == LocalDataSourceConfig {
    var fileManager: FileManager { get }
}

extension LocalDataSource {
    var fileManager: FileManager { configuration.fileManager }
}

struct LocalDataSourceConfig {
    let fileManager: FileManager
}

actor FileManager {}
