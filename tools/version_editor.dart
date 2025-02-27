import 'dart:io';

import 'command_runner.dart';
import 'tools_config.dart';

class VersionEditor {
  List<int> bumpPatchVersion() {
    var pubspecFile = File(Config.localPubspecPath);
    var snapcraftFile = File(Config.localSnapcraftPath);
    var oldVersion = readCurrentVersion();
    var newVersion = [oldVersion[0], oldVersion[1], oldVersion[2] + 1];

    _replaceLine(snapcraftFile, "version: '${oldVersion.join('.')}'",
        "version: '${newVersion.join('.')}'");
    _replaceLine(
        pubspecFile,
        'version: ${oldVersion.join('.')}+${oldVersion[2]}',
        'version: ${newVersion.join('.')}+${newVersion[2]}');

    runLocalCommand('git reset');
    runLocalCommand('git add ${pubspecFile.path} ${snapcraftFile.path}');
    runLocalCommand('git commit -m v${newVersion.join('.')}');
    runLocalCommand('git tag v${newVersion.join('.')} -f');
    runLocalCommand('git push && git push -f --tags');

    print(newVersion.join('.'));

    return newVersion;
  }

  List<int> readCurrentVersion() {
    var pubspecFile = File(Config.localPubspecPath);
    var content = pubspecFile.readAsStringSync();
    var lines = content.split('\n');
    var index = lines.indexWhere((element) => element.startsWith('version:'));
    String versionLine = lines[index];
    var versionPart =
        versionLine.substring('version: '.length, versionLine.indexOf('+'));
    var parts = versionPart.split('.').map((it) => int.parse(it));
    return parts.toList();
  }

  void _replaceLine(File file, Pattern lineMatch, String newLine) {
    var runnerFileContents = file.readAsStringSync();
    var lines = runnerFileContents.split('\n');
    var indexes = lines.where((element) => element.startsWith(lineMatch));
    if (indexes.length != 1) {
      throw Exception(
          'Not matching 1 line. Matches: ${indexes.length} Wanted: $lineMatch');
    }
    var index = lines.indexWhere((element) => element.startsWith(lineMatch));
    lines[index] = newLine;
    file.writeAsStringSync(lines.join('\n'));
  }
}
