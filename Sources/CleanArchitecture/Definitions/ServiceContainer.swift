/// @ServiceContainer
/// A macro that produces an init for the app services of a service container class and initializes
/// a property of UseCaseFactory. Additionally, it creates a view modifier, For example:
///
///     @ServiceContainer
///     final class ServiceContainer: ServiceProvider {
///         let authService: AuthService
///         let profileService: ProfileService
///     }
///
/// produces:
///
///     final class ServiceContainer: ServiceProvider {
///         let authService: AuthService
///         let profileService: ProfileService
///         let useCaseFactory = UseCaseFactory()
///
///         init(environment: AppEnvironment) {
///             self.authService = DefaultAuthService(useCaseFactory: useCaseFactory)
///             self.profileService = DefaultProfileService(useCaseFactory: useCaseFactory)
///         }
///     }
///
///     struct ServiceContainerModifier: ViewModifier {
///         let serviceContainer = ServiceContainer(environment: .current)
///
///         func body(content: Content) -> some View {
///         content
///             .environment(\\.authService, serviceContainer.authService)
///             .environment(\\.profileService, serviceContainer.profileService)
///         }
///     }
///
@attached(member, names: named(useCaseFactory), named(init))
@attached(peer, names: named(serviceContainer), named(ServiceContainerModifier))
public macro ServiceContainer() = #externalMacro(
    module: "CleanArchitectureMacros",
    type: "ServiceContainerMacro"
)
