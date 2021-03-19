import 'package:args/args.dart';
import 'package:convert_json_model/convert_json_model.dart';

void main(List<String> arguments) {
  var source = '';
  String? onlyFile = null;
  var output = '';
  var argParser = ArgParser();
  argParser
    ..addOption(
      'source',
      abbr: 's',
      defaultsTo: './jsons/',
      callback: (v) => source = v!,
      help: 'Specify source directory',
    )
    ..addOption(
      'output',
      abbr: 'o',
      defaultsTo: './lib/models/',
      callback: (v) => output = v!,
      help: 'Specify models directory',
    )
    ..addOption(
      'onlyFile',
      abbr: 'f',
      defaultsTo: null,
      callback: (v) => onlyFile = v,
      help: 'Specify file to read',
    )
    ..parse(arguments);
  var runner = JsonModelRunner(
      source: source, output: output, onlyFile: onlyFile ?? null);
  runner..setup();

  print('Start generating');
  if (runner.run()) {
    // cleanup on success
    print('Cleanup');
    runner.cleanup();
  }
}
