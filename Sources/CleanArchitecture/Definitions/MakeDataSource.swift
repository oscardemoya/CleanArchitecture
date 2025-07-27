/// #MakeDataSource
/// A macro that produces factory method of datasources for the clean architecture boilerplate.
/// If no concrete datasource implementation is specified it will return an instance of a datasource
/// named with the 'DefaultRemote' suffix. For example:
///
///     public struct DataSourceFactory {
///         let remoteDataSourceConfig: RemoteDataSourceConfig
///
///         #MakeDataSource<any AuthDataSource, RemoteDataSourceConfig>()
///     }
///
/// produces:
///
///     public struct DataSourceFactory {
///         let remoteDataSourceConfig: RemoteDataSourceConfig
///
///         func makeAuthDataSource() -> any AuthDataSource {
///             return DefaultAuthDataSource(configuration: remoteDataSourceConfig)
///         }
///     }
///
@freestanding(declaration, names: arbitrary)
public macro MakeDataSource<T, U>() = #externalMacro(
    module: "CleanArchitectureMacros",
    type: "MakeDataSourceMacro"
)
