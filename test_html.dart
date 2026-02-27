import 'dart:io';
import 'dart:convert';

void main() async {
  final request = await HttpClient()
      .getUrl(Uri.parse('https://enam.gov.in/web/dashboard/trade-data'));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  print('Length: \${body.length}');

  if (body.contains('table') || body.contains('td')) {
    print('Contains table!');
  }

  final regex = RegExp(r"Ajax_ctrl.*");
  final matches = regex.allMatches(body);
  final urls = matches.map((m) => m.group(0)).toSet();
  print('Found URLs: \$urls');
}
