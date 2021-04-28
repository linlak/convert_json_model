import 'package:convert_json_model/core/dart_declaration.dart';
import 'package:convert_json_model/core/decorator.dart';
import 'package:convert_json_model/core/json_key.dart';
import 'package:convert_json_model/core/json_model.dart';
import 'package:convert_json_model/utils/extensions.dart';

typedef Callback = DartDeclaration Function(
    DartDeclaration self, String testSubject,
    {String key, dynamic value});

class Command {
  Type? type = String;
  String? notprefix;
  String? prefix;
  String? command;
  Callback? callback;
  Command({
    this.type,
    this.prefix,
    this.notprefix,
    this.command,
    this.callback,
  });
}

class Commands {
  static final List<Command> keyComands = [
    Command(
      prefix: '\@',
      command: 'JsonKey',
      callback: (DartDeclaration self, String testSubject,
          {String? key, dynamic value}) {
        var jsonKey = JsonKeyMutate.fromJsonKeyParamaString(testSubject);

        self.jsonKey &= jsonKey;
        var newDeclaration = DartDeclaration.fromCommand(valueCommands, self,
            testSubject: value, key: key!, value: value);

        self.decorators.replaceDecorator(Decorator(self.jsonKey.toString()));
        // TODO: check nullsafety
        self.type = (DartDeclaration.getTypeFromJsonKey(testSubject) ??
                newDeclaration.type ??
                self.type)! +
            '?';
        //TODO: remove print
        print('JsonKey type ${self.type}');
        self.name = DartDeclaration.getNameFromJsonKey(testSubject) ??
            newDeclaration.name ??
            self.name;
        if (self.name == null) self.setName(value);
        return self;
      },
    ),
    Command(
      prefix: '\@',
      command: 'import',
      callback: (DartDeclaration self, dynamic testSubject,
          {String? key, dynamic value}) {
        self.addImport(value);

        return self;
      },
    ),
    Command(
      prefix: '@',
      command: '_',
      callback: (
        DartDeclaration self,
        dynamic testSubject, {
        String? key,
        dynamic value,
      }) {
        // TODO: nullsafety operator
        self.type = '${key!.substring(1)}?';
        self.name = value;

        return self;
      },
    ),
    Command(
      prefix: '',
      command: '',
      callback: (DartDeclaration self, dynamic testSubject,
          {String? key, dynamic value}) {
        self.setName(key!);

        if (value == null) {
          self.type = 'dynamic';
          return self;
        }

        if (value is Map) {
          // TODO: nullsafety operator
          self.type = '${key.toTitleCase()}?';
          self.nestedClasses.add(JsonModel.fromMap(key, value));
          return self;
        }

        if (value is List && value.isNotEmpty) {
          final firstListValue = value.first;
          if (firstListValue is List) {
            final nestedFirst = firstListValue.first;
            if (nestedFirst is Map) {
              final key = nestedFirst['\$key'];
              nestedFirst.remove('\$key');
              // TODO: nullsafety operator
              self.type = 'List<List<$key>>?';
              self.nestedClasses.add(JsonModel.fromMap(key, nestedFirst));
            }
          } else if (firstListValue is Map) {
            final key = firstListValue['\$key'];
            firstListValue.remove('\$key');
            // TODO: nullsafety operator
            self.type = 'List<$key>?';
            self.nestedClasses.add(JsonModel.fromMap(key, firstListValue));
          } else {
            final listValueType = firstListValue.runtimeType.toString();
            // TODO: nullsafety operator
            self.type = 'List<$listValueType>?';
          }
          return self;
        }

        var newDeclaration = DartDeclaration.fromCommand(
          valueCommands,
          self,
          testSubject: value,
          key: key,
          value: value,
        );
        // TODO: nullsafety operator
        self.type = newDeclaration.type ?? value.runtimeType.toString() + '?';

        return self;
      },
    ),
  ];
  static final List<Command> valueCommands = [
    Command(
      prefix: '\$',
      command: '\[\]',
      callback: (DartDeclaration self, String testSubject,
          {String? key, dynamic value}) {
        var typeName = testSubject
            .substring(3)
            .split('/')
            .last
            .split('\\')
            .last
            .toCamelCase();
        var toImport = testSubject.substring(3);
        self.addImport(toImport);
        // TODO: nullsafety operator
        self.type = 'List<${typeName.toTitleCase()}>?';
        return self;
      },
    ),
    Command(
      prefix: '\$',
      command: '',
      notprefix: '\$\[\]',
      callback: (DartDeclaration self, String testSubject,
          {String? key, dynamic value}) {
        self.setName(key!);

        var typeName = testSubject
            .substring(1)
            .split('/')
            .last
            .split('\\')
            .last
            .toCamelCase();

        var toImport = testSubject.substring(1);
        self.addImport(toImport);
// TODO: nullsafety operator
        var type = '${typeName.toTitleCase()}?';
        self.type = type;

        return self;
      },
    ),
    Command(
      prefix: '\@datetime',
      command: '',
      notprefix: '\$\[\]',
      callback: (DartDeclaration self, String testSubject,
          {String? key, dynamic value}) {
        self.setName(key!);
        // TODO: nullsafety operator
        self.type = 'DateTime?';
        return self;
      },
    ),
    Command(
      prefix: '\@enum',
      command: ':',
      notprefix: '\$\[\]',
      callback: (DartDeclaration self, String testSubject,
          {String? key, dynamic value}) {
        self.setEnumValues(
            (value as String).substring('@enum:'.length).split(','));
        print(key);
        self.setName(key!);
        return self;
      },
    ),
    Command(
      type: dynamic,
      callback: (DartDeclaration self, dynamic testSubject,
          {String? key, dynamic value}) {
        self.setName(key!);

        if (value == null) {
          self.type = 'dynamic';
          return self;
        }
        if (value is Map) {
          // TODO: nullsafety operator
          self.type = '${key.toTitleCase()}?';
          self.nestedClasses.add(JsonModel.fromMap('nested', value));
          return self;
        }
        // TODO: nullsafety operator
        //
        self.type = '${value.runtimeType.toString()}?';
        return self;
      },
    ),
  ];
}
