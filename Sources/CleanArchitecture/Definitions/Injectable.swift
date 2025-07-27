/// @Injectable
/// A macro that adds properties of a given set of protocols to be injected by its init method. For example:
///
///     @Injectable<RemoteDataSourceConfig>
///     public struct DataSourceFactory {
///     }
///
/// produces:
///
///     public struct DataSourceFactory {
///         private let remoteDataSourceConfig: RemoteDataSourceConfig
///
///         public init(remoteDataSourceConfig: RemoteDataSourceConfig) {
///             self.remoteDataSourceConfig = remoteDataSourceConfig
///         }
///     }
///
@attached(member, names: arbitrary)
public macro Injectable<T>() = #externalMacro(
    module: "CleanArchitectureMacros",
    type: "InjectableMacro"
)
