// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/tokens_context.dart';

/// The context of a unit - the context of the bundle, and the unit tokens.
class LinkedUnitContext {
  final LinkedBundleContext bundleContext;
  final TokensContext tokensContext;

  LinkedUnitContext(this.bundleContext, this.tokensContext);

  Iterable<LinkedNode> classFields(LinkedNode class_) sync* {
    for (var declaration in class_.classOrMixinDeclaration_members) {
      if (declaration.kind == LinkedNodeKind.fieldDeclaration) {
        var variableList = declaration.fieldDeclaration_fields;
        for (var field in variableList.variableDeclarationList_variables) {
          yield field;
        }
      }
    }
  }

  String getCommentText(LinkedNode comment) {
    if (comment == null) return null;

    return comment.comment_tokens.map(getTokenLexeme).join('\n');
  }

  String getConstructorDeclarationName(LinkedNode node) {
    var name = node.constructorDeclaration_name;
    if (name != null) {
      return getSimpleName(name);
    }
    return '';
  }

  String getFormalParameterName(LinkedNode node) {
    return getSimpleName(node.normalFormalParameter_identifier);
  }

  List<LinkedNode> getFormalParameters(LinkedNode node) {
    LinkedNode parameterList;
    var kind = node.kind;
    if (kind == LinkedNodeKind.constructorDeclaration) {
      parameterList = node.constructorDeclaration_parameters;
    } else if (kind == LinkedNodeKind.functionDeclaration) {
      return getFormalParameters(node.functionDeclaration_functionExpression);
    } else if (kind == LinkedNodeKind.functionExpression) {
      parameterList = node.functionExpression_formalParameters;
    } else if (kind == LinkedNodeKind.functionTypeAlias) {
      parameterList = node.functionTypeAlias_formalParameters;
    } else if (kind == LinkedNodeKind.genericFunctionType) {
      parameterList = node.genericFunctionType_formalParameters;
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      parameterList = node.methodDeclaration_formalParameters;
    } else {
      throw UnimplementedError('$kind');
    }
    return parameterList?.formalParameterList_parameters;
  }

  DartType getFormalParameterType(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.defaultFormalParameter) {
      return getFormalParameterType(node.defaultFormalParameter_parameter);
    }
    if (kind == LinkedNodeKind.fieldFormalParameter) {
      return getType(node.fieldFormalParameter_type2);
    }
    if (kind == LinkedNodeKind.functionTypedFormalParameter) {
      return getType(node.functionTypedFormalParameter_type2);
    }
    if (kind == LinkedNodeKind.simpleFormalParameter) {
      return getType(node.simpleFormalParameter_type2);
    }
    throw UnimplementedError('$kind');
  }

  LinkedNode getImplementsClause(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.classDeclaration) {
      return node.classOrMixinDeclaration_implementsClause;
    } else if (kind == LinkedNodeKind.classTypeAlias) {
      return node.classTypeAlias_implementsClause;
    } else if (kind == LinkedNodeKind.mixinDeclaration) {
      return node.classOrMixinDeclaration_implementsClause;
    } else {
      throw UnimplementedError('$kind');
    }
  }

  InterfaceType getInterfaceType(LinkedNodeType linkedType) {
    return bundleContext.getInterfaceType(linkedType);
  }

  List<LinkedNode> getLibraryMetadataOrEmpty(LinkedNode unit) {
    for (var directive in unit.compilationUnit_directives) {
      if (directive.kind == LinkedNodeKind.libraryDirective) {
        return getMetadataOrEmpty(directive);
      }
    }
    return const <LinkedNode>[];
  }

  List<LinkedNode> getMetadataOrEmpty(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.classDeclaration ||
        kind == LinkedNodeKind.classTypeAlias ||
        kind == LinkedNodeKind.constructorDeclaration ||
        kind == LinkedNodeKind.enumConstantDeclaration ||
        kind == LinkedNodeKind.enumDeclaration ||
        kind == LinkedNodeKind.exportDirective ||
        kind == LinkedNodeKind.functionDeclaration ||
        kind == LinkedNodeKind.functionTypeAlias ||
        kind == LinkedNodeKind.libraryDirective ||
        kind == LinkedNodeKind.importDirective ||
        kind == LinkedNodeKind.methodDeclaration ||
        kind == LinkedNodeKind.mixinDeclaration ||
        kind == LinkedNodeKind.partDirective ||
        kind == LinkedNodeKind.partOfDirective ||
        kind == LinkedNodeKind.variableDeclaration) {
      return node.annotatedNode_metadata;
    }
    if (kind == LinkedNodeKind.defaultFormalParameter) {
      return getMetadataOrEmpty(node.defaultFormalParameter_parameter);
    }
    if (kind == LinkedNodeKind.fieldFormalParameter ||
        kind == LinkedNodeKind.functionTypedFormalParameter ||
        kind == LinkedNodeKind.simpleFormalParameter) {
      return node.normalFormalParameter_metadata;
    }
    return const <LinkedNode>[];
  }

  String getMethodName(LinkedNode node) {
    return getSimpleName(node.methodDeclaration_name);
  }

  DartType getReturnType(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.functionDeclaration) {
      return getType(node.functionDeclaration_returnType2);
    } else if (kind == LinkedNodeKind.functionTypeAlias) {
      return getType(node.functionTypeAlias_returnType2);
    } else if (kind == LinkedNodeKind.genericFunctionType) {
      return getType(node.genericFunctionType_returnType2);
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      return getType(node.methodDeclaration_returnType2);
    } else {
      throw UnimplementedError('$kind');
    }
  }

  String getSimpleName(LinkedNode node) {
    return getTokenLexeme(node.simpleIdentifier_token);
  }

  List<String> getSimpleNameList(List<LinkedNode> nodeList) {
    return nodeList.map(getSimpleName).toList();
  }

  int getSimpleOffset(LinkedNode node) {
    return tokensContext.offset(node.simpleIdentifier_token);
  }

  String getStringContent(LinkedNode node) {
    return node.simpleStringLiteral_value;
  }

  String getTokenLexeme(int token) {
    return tokensContext.lexeme(token);
  }

  DartType getType(LinkedNodeType linkedType) {
    return bundleContext.getType(linkedType);
  }

  DartType getTypeAnnotationType(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.typeName) {
      return getType(node.typeName_type);
    } else {
      throw UnimplementedError('$kind');
    }
  }

  String getUnitMemberName(LinkedNode node) {
    return getSimpleName(node.namedCompilationUnitMember_name);
  }

  String getVariableName(LinkedNode node) {
    return getSimpleName(node.variableDeclaration_name);
  }

  bool isAbstract(LinkedNode node) {
    return node.kind == LinkedNodeKind.methodDeclaration &&
        node.methodDeclaration_body.kind == LinkedNodeKind.emptyFunctionBody;
  }

  bool isAsynchronous(LinkedNode node) {
    LinkedNode body = _getFunctionBody(node);
    if (body.kind == LinkedNodeKind.blockFunctionBody) {
      return isAsyncKeyword(body.blockFunctionBody_keyword);
    } else if (body.kind == LinkedNodeKind.emptyFunctionBody) {
      return false;
    } else {
      return isAsyncKeyword(body.expressionFunctionBody_keyword);
    }
  }

  bool isAsyncKeyword(int token) {
    return tokensContext.type(token) == UnlinkedTokenType.ASYNC;
  }

  bool isConst(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.defaultFormalParameter) {
      return isConst(node.defaultFormalParameter_parameter);
    }
    if (kind == LinkedNodeKind.simpleFormalParameter) {
      return isConstKeyword(node.simpleFormalParameter_keyword);
    }
    if (kind == LinkedNodeKind.variableDeclaration) {
      return node.variableDeclaration_declaration.isConst;
    }
    throw UnimplementedError('$kind');
  }

  bool isConstKeyword(int token) {
    return tokensContext.type(token) == UnlinkedTokenType.CONST;
  }

  bool isConstVariableList(LinkedNode node) {
    return isConstKeyword(node.variableDeclarationList_keyword);
  }

  bool isExternal(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.constructorDeclaration) {
      return node.constructorDeclaration_externalKeyword != 0;
    } else if (kind == LinkedNodeKind.functionDeclaration) {
      return node.functionDeclaration_externalKeyword != 0;
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      return node.methodDeclaration_externalKeyword != 0;
    } else {
      throw UnimplementedError('$kind');
    }
  }

  bool isFinal(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.defaultFormalParameter) {
      return isFinal(node.defaultFormalParameter_parameter);
    }
    if (kind == LinkedNodeKind.enumConstantDeclaration) {
      return false;
    }
    if (kind == LinkedNodeKind.fieldFormalParameter) {
      return isFinalKeyword(node.fieldFormalParameter_keyword);
    }
    if (kind == LinkedNodeKind.functionTypedFormalParameter) {
      return false;
    }
    if (kind == LinkedNodeKind.simpleFormalParameter) {
      return isFinalKeyword(node.simpleFormalParameter_keyword);
    }
    if (kind == LinkedNodeKind.variableDeclaration) {
      return node.variableDeclaration_declaration.isFinal;
    }
    throw UnimplementedError('$kind');
  }

  bool isFinalKeyword(int token) {
    return tokensContext.type(token) == UnlinkedTokenType.FINAL;
  }

  bool isFinalVariableList(LinkedNode node) {
    return isFinalKeyword(node.variableDeclarationList_keyword);
  }

  bool isFunction(LinkedNode node) {
    return node.kind == LinkedNodeKind.functionDeclaration;
  }

  bool isGenerator(LinkedNode node) {
    LinkedNode body = _getFunctionBody(node);
    if (body.kind == LinkedNodeKind.blockFunctionBody) {
      return body.blockFunctionBody_star != 0;
    }
    return false;
  }

  bool isGetter(LinkedNode node) {
    return isGetterMethod(node) || isGetterFunction(node);
  }

  bool isGetterFunction(LinkedNode node) {
    return isFunction(node) &&
        _isGetToken(node.functionDeclaration_propertyKeyword);
  }

  bool isGetterMethod(LinkedNode node) {
    return isMethod(node) &&
        _isGetToken(node.methodDeclaration_propertyKeyword);
  }

  bool isLibraryKeyword(int token) {
    return tokensContext.type(token) == UnlinkedTokenType.LIBRARY;
  }

  bool isMethod(LinkedNode node) {
    return node.kind == LinkedNodeKind.methodDeclaration;
  }

  bool isSetter(LinkedNode node) {
    return isSetterMethod(node) || isSetterFunction(node);
  }

  bool isSetterFunction(LinkedNode node) {
    return isFunction(node) &&
        _isSetToken(node.functionDeclaration_propertyKeyword);
  }

  bool isSetterMethod(LinkedNode node) {
    return isMethod(node) &&
        _isSetToken(node.methodDeclaration_propertyKeyword);
  }

  bool isStatic(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.functionDeclaration) {
      return true;
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      return node.methodDeclaration_modifierKeyword != 0;
    } else if (kind == LinkedNodeKind.variableDeclaration) {
      return node.variableDeclaration_declaration.isStatic;
    }
    throw UnimplementedError('$kind');
  }

  bool isSyncKeyword(int token) {
    return tokensContext.type(token) == UnlinkedTokenType.SYNC;
  }

  void loadClassMemberReferences(Reference reference) {
    var node = reference.node;
    if (node.kind != LinkedNodeKind.classDeclaration &&
        node.kind != LinkedNodeKind.mixinDeclaration) {
      return;
    }

    var constructorContainerRef = reference.getChild('@constructor');
    var fieldContainerRef = reference.getChild('@field');
    var methodContainerRef = reference.getChild('@method');
    var getterContainerRef = reference.getChild('@getter');
    var setterContainerRef = reference.getChild('@setter');
    for (var member in node.classOrMixinDeclaration_members) {
      if (member.kind == LinkedNodeKind.constructorDeclaration) {
        var name = getConstructorDeclarationName(member);
        constructorContainerRef.getChild(name).node = member;
      } else if (member.kind == LinkedNodeKind.fieldDeclaration) {
        var variableList = member.fieldDeclaration_fields;
        for (var field in variableList.variableDeclarationList_variables) {
          var name = getSimpleName(field.variableDeclaration_name);
          fieldContainerRef.getChild(name).node = field;
        }
      } else if (member.kind == LinkedNodeKind.methodDeclaration) {
        var name = getSimpleName(member.methodDeclaration_name);
        var propertyKeyword = member.methodDeclaration_propertyKeyword;
        if (_isGetToken(propertyKeyword)) {
          getterContainerRef.getChild(name).node = member;
        } else if (_isSetToken(propertyKeyword)) {
          setterContainerRef.getChild(name).node = member;
        } else {
          methodContainerRef.getChild(name).node = member;
        }
      }
    }
  }

  Expression readInitializer(ElementImpl enclosing, LinkedNode linkedNode) {
    var reader = AstBinaryReader(this);
    return reader.withLocalScope(enclosing, () {
      if (linkedNode.kind == LinkedNodeKind.defaultFormalParameter) {
        var data = linkedNode.defaultFormalParameter_defaultValue;
        return reader.readNode(data);
      }
      var data = linkedNode.variableDeclaration_initializer;
      return reader.readNode(data);
    });
  }

  AstNode readNode(LinkedNode linkedNode) {
    var reader = AstBinaryReader(this);
    return reader.readNode(linkedNode);
  }

  void setReturnType(LinkedNodeBuilder node, DartType type) {
    var typeData = bundleContext.linking.writeType(type);
    node.functionDeclaration_returnType2 = typeData;
  }

  void setVariableType(LinkedNodeBuilder node, DartType type) {
    var typeData = bundleContext.linking.writeType(type);
    node.simpleFormalParameter_type2 = typeData;
  }

  Iterable<LinkedNode> topLevelVariables(LinkedNode unit) sync* {
    for (var declaration in unit.compilationUnit_declarations) {
      if (declaration.kind == LinkedNodeKind.topLevelVariableDeclaration) {
        var variableList = declaration.topLevelVariableDeclaration_variableList;
        for (var variable in variableList.variableDeclarationList_variables) {
          yield variable;
        }
      }
    }
  }

  LinkedNode _getFunctionBody(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.constructorDeclaration) {
      return node.constructorDeclaration_body;
    } else if (kind == LinkedNodeKind.functionDeclaration) {
      return _getFunctionBody(node.functionDeclaration_functionExpression);
    } else if (kind == LinkedNodeKind.functionExpression) {
      return node.functionExpression_body;
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      return node.methodDeclaration_body;
    } else {
      throw UnimplementedError('$kind');
    }
  }

  bool _isGetToken(int token) {
    return tokensContext.type(token) == UnlinkedTokenType.GET;
  }

  bool _isSetToken(int token) {
    return tokensContext.type(token) == UnlinkedTokenType.SET;
  }

  static List<LinkedNode> getTypeParameters(LinkedNode node) {
    LinkedNode typeParameterList;
    var kind = node.kind;
    if (kind == LinkedNodeKind.classTypeAlias) {
      typeParameterList = node.classTypeAlias_typeParameters;
    } else if (kind == LinkedNodeKind.classDeclaration ||
        kind == LinkedNodeKind.mixinDeclaration) {
      typeParameterList = node.classOrMixinDeclaration_typeParameters;
    } else if (kind == LinkedNodeKind.constructorDeclaration) {
      return const [];
    } else if (kind == LinkedNodeKind.functionDeclaration) {
      return getTypeParameters(node.functionDeclaration_functionExpression);
    } else if (kind == LinkedNodeKind.functionExpression) {
      typeParameterList = node.functionExpression_typeParameters;
    } else if (kind == LinkedNodeKind.functionTypeAlias) {
      typeParameterList = node.functionTypeAlias_typeParameters;
    } else if (kind == LinkedNodeKind.genericFunctionType) {
      typeParameterList = node.genericFunctionType_typeParameters;
    } else if (kind == LinkedNodeKind.genericTypeAlias) {
      typeParameterList = node.genericTypeAlias_typeParameters;
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      typeParameterList = node.methodDeclaration_typeParameters;
    } else {
      throw UnimplementedError('$kind');
    }
    return typeParameterList?.typeParameterList_typeParameters;
  }
}
