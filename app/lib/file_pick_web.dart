import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

import 'picked_file.dart';

Future<PickedFile?> pickRequestFile() {
  final input = HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/jpeg,image/png,image/webp,application/pdf';
  final result = Completer<PickedFile?>();
  input.onchange = ((Event _) {
    final file = input.files?.item(0);
    input.remove();
    if (file == null) {
      if (!result.isCompleted) result.complete(null);
      return;
    }
    file.arrayBuffer().toDart.then((buffer) {
      if (result.isCompleted) return;
      result.complete(
        PickedFile(name: file.name, bytes: Uint8List.view(buffer.toDart)),
      );
    });
  }).toJS;
  document.body?.append(input);
  input.click();
  return result.future;
}
