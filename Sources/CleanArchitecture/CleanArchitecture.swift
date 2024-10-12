// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces factory of use cases for the clean architecture boilerplate
/// when applied to a use case concrete implemetation. For example:
///
///     @UseCase
///     struct EmailLogin {
///         let authRepository: AuthRepository
///         let profileRepository: ProfileRepository
///
///         func execute(email: String, password: String) async throws -> User {
///             var user = try await authRepository.logIn(email: email, password: password)
///             user.profile = try await profileRepository.profile(for: user)
///             return user
///         }
///     }
///
/// produces:
///
///     public protocol EmailLoginUseCase {
///         func execute(email: String, password: String) async throws -> User
///     }
///
///     class EmailLoginDefaultUseCase: EmailLoginUseCase {
///         let authRepository: AuthRepository
///         let profileRepository: ProfileRepository
///         let useCase: EmailLogin
///
///         init(authRepository: AuthRepository, profileRepository: ProfileRepository) {
///             self.authRepository = authRepository
///             self.profileRepository = profileRepository
///             self.useCase = EmailLogin(authRepository: authRepository, profileRepository: ProfileRepository)
///         }
///
///         func execute(email: String, password: String) async throws -> User {
///             useCase.execute(email: email, password: password)
///         }
///     }
///
///     public class EmailLoginFactory {
///         public static func makeUseCase(authRepository: AuthRepository, profileRepository: ProfileRepository) -> EmailLoginUseCase {
///             EmailLoginDefaultUseCase(authRepository: authRepository, profileRepository: profileRepository)
///         }
///     }
///
@attached(peer, names: suffixed(UseCase), suffixed(DefaultUseCase), suffixed(Factory))
public macro UseCase() = #externalMacro(module: "CleanArchitectureMacros", type: "UseCaseMacro")

