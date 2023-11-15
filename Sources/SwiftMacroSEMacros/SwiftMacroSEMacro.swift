import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

@main
struct SwiftMacroSEPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
    ]
}



public struct InitTo: MemberMacro {
    public static func expansion<Declaration: DeclGroupSyntax,
                                 Context: MacroExpansionContext>(of node: AttributeSyntax,
                                                                 providingMembersOf declaration: Declaration,
                                                                 in context: Context) throws -> [DeclSyntax] {
        guard [SwiftSyntax.SyntaxKind.classDecl, .structDecl].contains(declaration.kind) else {
            fatalError("type error")
        }
        
        let (parameters, body) = initBodyAndParams(for: declaration)
        
        var parametersLiteral = "init(\(parameters.joined(separator: ", ")))"
        
        parametersLiteral = "\(declaration.modifiers)\(parametersLiteral)"

        let bodyItem = CodeBlockItemListSyntax.init(stringLiteral: body.joined(separator: "\n"))
        
        let initDecl = try InitializerDeclSyntax(SyntaxNodeString(stringLiteral: parametersLiteral),bodyBuilder: { bodyItem })

        return [DeclSyntax(initDecl)]
    }

    private static func initBodyAndParams(for declaration: DeclGroupSyntax) -> (params: [String], body: [String]) {
        var parameters: [String] = []
        var body: [String] = []
        
        declaration.memberBlock.members.forEach { member in
            if let patternBinding = member.decl.as(VariableDeclSyntax.self)?.bindings
                .as(PatternBindingListSyntax.self)?.first?.as(PatternBindingSyntax.self),
               let identifier = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
               let type =  patternBinding.typeAnnotation?.as(TypeAnnotationSyntax.self)?.type {
                var parameter = "\(identifier): "
                if type.is(FunctionTypeSyntax.self) {
                    parameter += "@escaping "
                }
                parameter += "\(type)"
                if type.is(OptionalTypeSyntax.self) {
                    parameter += " = nil"
                }
                parameters.append(parameter)
                body.append("self.\(identifier) = \(identifier)")
            }
        }
        return (params: parameters, body: body)
    }

     
}
