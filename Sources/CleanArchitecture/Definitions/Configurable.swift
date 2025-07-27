/// @Configurable
/// A macro that adds configuration property and its init method. For example:
///
///     @Configurable<RemoteDataSourceConfig>
///     final class DefaultAuthDataSource: AuthDataSource {
///     }
///
/// produces:
///
///     final class DefaultAuthDataSource: AuthDataSource {
///         let configuration: RemoteDataSourceConfig
///
///         public init(configuration: RemoteDataSourceConfig) {
///             self.configuration = configuration
///         }
///     }
///
@attached(member, names: arbitrary)
public macro Configurable<T>() = #externalMacro(
    module: "CleanArchitectureMacros",
    type: "ConfigurableMacro"
)
