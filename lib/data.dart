import 'dart:convert';

class DDocument{
  final Map<String, Object?> _json;
  DDocument() : _json = jsonDecode(documentJson);


  ({int x, int y, int Function(int x, int y) function}) get p{
    final pt = (x : 10, y : 20, function : (int x, int y) => x+y);
    return pt;
  }


  (String, {DateTime modified}) get metadata{
    const title = 'My Document';
    final now = DateTime.now();

    return (title, modified: now);
  }

}

const String documentJson = '''
{
  "metadata": {
    "title": "My Document",
    "modified": "2023-05-10"
  },
  "blocks": [
    {
      "type": "h1",
      "text": "Chapter 1"
    },
    {
      "type": "p",
      "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    },
    {
      "type": "checkbox",
      "checked": false,
      "text": "Learn Dart 3"
    }
  ]
}
''';