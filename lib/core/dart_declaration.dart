import 'dart:collection';
import 'dart:io';

import 'package:convert_json_model/core/command.dart';
import 'package:convert_json_model/core/decorator.dart';
import 'package:convert_json_model/core/json_key.dart';
import 'package:convert_json_model/core/json_model.dart';
import 'package:convert_json_model/core/model_template.dart';
import 'package:convert_json_model/utils/extensions.dart';

class DartDeclaration {
  JsonKeyMutate jsonKey;
  List<Decorator> decorators = [];
  List<String> imports = [];
  String? type;
  String? name;
  String? assignment;
  List<Command> keyComands = [];
  List<Command> valueCommands = [];
  List<String> enumValues = [];
  List<JsonModel> nestedClasses = [];
  bool get isEnum => enumValues.isNotEmpty;

  DartDeclaration({
    required this.jsonKey,
    this.type,
    this.name,
    this.assignment,
  }) {
    keyComands = Commands.keyComands;
    valueCommands = Commands.valueCommands;
  }

  String toDeclaration(String className) {
    var declaration = '';

    if (isEnum) {
      declaration += '${getEnum(className).toImport()}\n';
    }

    declaration +=
        '${stringifyDecorator(getDecorator())}$type $name${stringifyAssignment(assignment)};'
            .trim();

    return ModelTemplates.indented(declaration);
  }

  String stringifyAssignment(value) {
    return value != null ? ' = $value' : '';
  }

  String nullableModefier(value) {
    return value != null ? '?' : '';
  }

  String stringifyDecorator(deco) {
    return deco != null && deco.isNotEmpty ? '$deco ' : '';
  }

  String? getDecorator() {
    return decorators.join('\n');
  }

  List<String> getImportStrings() {
    return imports
        .where((element) => element.isNotEmpty)
        .map((e) => "import '$e.dart';")
        .toList();
  }

  static String? getTypeFromJsonKey(String theString) {
    var declare = theString.split(')').last.trim().split(' ');
    if (declare.isNotEmpty) return declare.first;
    return null;
  }

  static String? getNameFromJsonKey(String theString) {
    var declare = theString.split(')').last.trim().split(' ');
    if (declare.length > 1) return declare.last;
    return null;
  }

  static String getParameterString(String theString) {
    return theString.split('(')[1].split(')')[0];
  }

  void setName(String newName) {
    name = newName;
    if (newName.isTitleCase() || newName.contains(RegExp(r'[_\W]'))) {
      jsonKey.addKey(name: newName);
      name = newName.toCamelCase();
      decorators.replaceDecorator(Decorator(jsonKey.toString()));
    }
  }

  void setEnumValues(List<String> values) {
    enumValues = values;
    // TODO: nullsafety operator
    type = '${_detectType(values.first)}?';
  }

/**
 * gets enum from [className]
 * getEnum('User');
 */
  Enum getEnum(String className) {
    return Enum(className, name!, enumValues);
  }

  void addImport(import) {
    if (import == null && !import.isNotEmpty) {
      return;
    }
    if (import is List) {
      imports.addAll(import.map((e) => e));
    }
    if (import != null && import.isNotEmpty) imports.add(import);

    imports = LinkedHashSet<String>.from(imports).toList();
  }

  static DartDeclaration fromKeyValue(key, val) {
    var dartDeclaration = DartDeclaration(jsonKey: JsonKeyMutate());
    dartDeclaration = fromCommand(
      Commands.valueCommands,
      dartDeclaration,
      testSubject: val,
      key: key,
      value: val,
    );

    dartDeclaration = fromCommand(Commands.keyComands, dartDeclaration,
        testSubject: key, key: key, value: val);
    if (dartDeclaration.type == null || dartDeclaration.name == null) {
      exit(0);
    }
    return dartDeclaration;
  }

  static DartDeclaration fromCommand(List<Command> commandList, self,
      {dynamic testSubject, required String key, dynamic value}) {
    var newSelf = self;
    for (var command in commandList) {
      if (testSubject is String) {
        if ((command.prefix != null &&
            testSubject.startsWith(command.prefix!))) {
          if ((command.prefix != null &&
                  command.command != null &&
                  testSubject.startsWith(command.prefix! + command.command!)) ||
              (command.command != null &&
                  testSubject.startsWith(command.command!))) {
            if (command.notprefix != null &&
                    !testSubject.startsWith(command.notprefix!) ||
                command.notprefix == null) {
              newSelf =
                  command.callback!(self, testSubject, key: key, value: value);
              break;
            }
          }
        }
      }
      if (testSubject.runtimeType == command.type) {
        newSelf = command.callback!(self, testSubject, key: key, value: value);
        break;
      }
    }
    return newSelf;
  }
}

class Enum {
  final String className;
  final String name;
  final List<String> values;

  var valueType = 'String';

  String get enumName => '$className${name.toTitleCase()}Enum';
  String get converterName => '_${enumName.toTitleCase()}Converter';
  String get enumValuesMapName => '_${enumName.toCamelCase()}Values';

  Enum(this.className, this.name, this.values) {
    valueType = _detectType(values.first);
  }

  String valueName(String input) {
    if (input.contains('(')) {
      return input.substring(0, input.indexOf('(')).toTitleCase();
    } else {
      return input.toTitleCase();
    }
  }

  String valuesForTemplate() {
    return values.map((e) {
      final value = e.between('(', ')');
      if (value != null) {
        return '  $value: $enumName.${valueName(e)},';
      } else {
        return '  \'$e\': $enumName.${valueName(e)},';
      }
    }).join('\n');
  }

  String toTemplateString() {
    return '''
enum $enumName { ${values.map((e) => valueName(e)).toList().join(', ')} }


final $enumValuesMapName = $converterName({
${valuesForTemplate()}
});


class $converterName<$valueType, O> {
  Map<$valueType, O> map;
  Map<O, $valueType>? reverseMap;

  $converterName(this.map);

  Map<O, $valueType> get reverse => reverseMap ??= map.map((k, v) => MapEntry(v, k));
}
''';
  }

  String toImport() {
    return '''
$enumName 
  get ${enumName.toCamelCase()} => $enumValuesMapName.map[$name] as $enumName;
  set ${enumName.toCamelCase()}($enumName value) => $name = $enumValuesMapName.reverse[value]!;''';
  }
}

String _detectType(String value) {
  final firstValue = value.between('(', ')');
  if (firstValue != null) {
    final isInt = (int.tryParse(firstValue) ?? '') is int;
    if (isInt) {
      return 'int';
    }
  }
  return 'String';
}
