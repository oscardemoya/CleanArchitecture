/// @Entity
/// A macro that produces a default initializer for Domain models (Entities). For example:
///
///     @Entity
///     struct LoginCredentials {
///         let email: String
///         let password: String
///     }
///
/// produces:
///
///     struct LoginCredentials {
///         let email: String
///         let password: String
///
///         init(email: String, password: String) {
///             self.email = email
///             self.password = password
///         }
///     }
///
@attached(member, names: named(init), named(==))
public macro Entity() = #externalMacro(
    module: "CleanArchitectureMacros",
    type: "EntityMacro"
)

/// Marks a property to be included in Equatable comparison
/// Use @EquatableKey for properties that define entity identity
@attached(peer)
public macro EquatableKey() = #externalMacro(
    module: "CleanArchitectureMacros",
    type: "EquatableKeyMacro"
)
