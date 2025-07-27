/// #MakeUseCase
/// A macro that produces factory method of use cases for the clean architecture boilerplate.
/// A list of repository protocols joined by '&' should be passed in the generic clause
/// and the name of the protocol of the use case must be pass as parameter. For example:
///
///     struct UseCaseFactory {
///         #MakeUseCase<AuthRepository & ProfileRepository, LoginUseCase>()
///     }
///
/// produces:
///
///     struct UseCaseFactory {
///         public static func makeLoginUseCase() -> LoginUseCase {
///             let authRepository = RepositoryFactory.makeAuthRepository()
///             let profileRepository = RepositoryFactory.makeProfileRepository()
///             return LoginUseCase(authRepository: authRepository, profileRepository: profileRepository)
///         }
///     }
///
@freestanding(declaration, names: arbitrary)
public macro MakeUseCase<RepositoryTypes, UseCaseType, each Dependencies>() = #externalMacro(
    module: "CleanArchitectureMacros",
    type: "MakeUseCaseMacro"
)
