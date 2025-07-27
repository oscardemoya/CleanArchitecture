/// @ModelConvertible
/// A macro that produces conversion methods for a data model to its corresponding domain entity.
/// Adds `asDomainEntity` computed property a default init and an `init(entity:)` initializer. For example:
///
///     @ModelConvertible
///     struct LoginCredentialsData {
///         @Convertible(key: "username")
///         let idNumber: String
///         let password: String
///     }
///
/// produces:
///
///     struct LoginCredentialsData {
///         let idNumber: String
///         let password: String
///
///         var asDomainEntity: LoginCredentials {
///             .init(
///                 username: idNumber,
///                 password: password
///             )
///         }
///
///         init(idNumber: String, password: String) {
///             self.idNumber = idNumber
///             self.password = password
///         }
///
///         init(entity: LoginCredentials) {
///             self.init(
///                 idNumber: entity.username,
///                 password: entity.password
///             )
///         }
///     }
///
@attached(member, names: named(asDomainEntity), named(init), named(init(entity:)))
public macro ModelConvertible() = #externalMacro(
    module: "CleanArchitectureMacros",
    type: "ModelConvertibleMacro"
)

/// Marks a property for custom mapping between Data and Domain models
/// when used in a model marked with `@ModelConvertible`.
@attached(peer)
public macro Convertible(key: String) = #externalMacro(
    module: "CleanArchitectureMacros",
    type: "ConvertibleMacro"
)
