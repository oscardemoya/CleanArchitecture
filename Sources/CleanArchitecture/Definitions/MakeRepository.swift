/// #MakeRepository
/// A macro that produces factory method of repositories for the clean architecture boilerplate.
/// If no concrete repository implementation is specified it will return an instance of a repository
/// named with the 'Default' suffix. For example:
///
///     struct RepositoryFactory {
///         private let dataSourceFactory: DataSourceFactory
///
///         public init(dataSourceFactory: DataSourceFactory) {
///             self.dataSourceFactory = dataSourceFactory
///         }
///
///         #MakeRepository<AuthRepository>()
///     }
///
/// produces:
///
///     struct RepositoryFactory {
///         private let dataSourceFactory: DataSourceFactory
///
///         public init(dataSourceFactory: DataSourceFactory) {
///             self.dataSourceFactory = dataSourceFactory
///         }
///
///         public func makeAuthRepository() -> AuthRepository {
///             let dataSource = dataSourceFactory.makeAuthDataSource()
///             DefaultAuthRepository(dataSource: dataSource)
///         }
///     }
///
@freestanding(declaration, names: arbitrary)
public macro MakeRepository<T>(_ type: Any.Type? = nil) = #externalMacro(
    module: "CleanArchitectureMacros",
    type: "MakeRepositoryMacro"
)
