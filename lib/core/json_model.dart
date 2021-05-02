import 'package:convert_json_model/core/dart_declaration.dart';

import 'package:convert_json_model/utils/extensions.dart';

class JsonModel {
  JsonModel(String fileName, List<DartDeclaration> dartDeclarations) {
    this.fileName = fileName;
    className = fileName.toTitleCase();
    declaration = dartDeclarations.toDeclarationStrings(className!);
    imports = dartDeclarations.toImportStrings();
    argsParams = dartDeclarations.toArgsStrings(className!);
    imports_raw = dartDeclarations.getImportRaw();
    enums = dartDeclarations.getEnums(className!);
    nestedClasses = dartDeclarations.getNestedClasses();
  }

  /// model string from json map
  static JsonModel fromMap(String fileName, Map jsonMap) {
    var dartDeclarations = <DartDeclaration>[];
    jsonMap.forEach((key, value) {
      var declaration = DartDeclaration.fromKeyValue(key, value);

      return dartDeclarations.add(declaration);
    });

    /// add key to templatestring
    /// add valuetype to templatestring
    return JsonModel(fileName, dartDeclarations);
  }
  
  String? fileName;
  String? className;
  String? declaration;
  String? argsParams;
  String? imports;
  List<String>? imports_raw;
  String? enums;
  String? enumConverters;
  String? nestedClasses;

}
