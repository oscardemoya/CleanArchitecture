/// A macro that produces an init for the use cases of a service class using the factory use case container.
/// Additionally, it creates a shared instance for this class. For example:
///
///     @AppService
///     final class ProfileService: @unchecked Sendable, ObservableObject {
///         private var fetchCurrentUserUseCase: FetchCurrentUserUseCase
///     }
///
/// produces:
///
///     final class ProfileService: @unchecked Sendable, ObservableObject {
///         private var fetchCurrentUserUseCase: FetchCurrentUserUseCase
///
///         static let shared = ProfileService()
///
///         private init() {
///             self.fetchCurrentUserUseCase = UseCaseFactory.makeFetchCurrentUserUseCase()
///         }
///     }
///
@attached(member, names: named(shared), named(init))
public macro AppService<T>() = #externalMacro(
    module: "CleanArchitectureMacros",
    type: "AppServiceMacro"
)
