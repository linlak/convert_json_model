class Decorator {
  Decorator(String fullString) {
    prfix = fullString.split('(').first;
    string = fullString;
  }

  String prfix = '';
  String string = '';
  @override
  String toString() {
    return string;
  }
}

extension DecoratorList on List<Decorator> {
  void replaceDecorator(Decorator decorator) {
    removeWhere((element) => element.prfix == decorator.prfix);
    add(decorator);
  }
}
