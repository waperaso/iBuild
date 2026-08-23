import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import '../lib/src/ai/openai_client.dart';

void main() {
  test('completeWithImages posts two image_url parts and json_object mode', () async {
    Map<String, dynamic>? captured;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((req) async {
      final raw = await utf8.decoder.bind(req).join();
      captured = jsonDecode(raw) as Map<String, dynamic>;
      req.response.headers.contentType = ContentType.json;
      req.response.write(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content':
                    '{"verdict":"needs_review","confidence":0.2,"summary":"ok"}',
              },
            },
          ],
        }),
      );
      await req.response.close();
    });

    final client = OpenAiClient(
      apiKey: 'sk-test',
      baseUrl: 'http://127.0.0.1:${server.port}/v1',
    );
    final out = await client.completeWithImages(
      systemPrompt: 'return json',
      userText: '{"photoA":{"id":"a"}}',
      imageDataUrls: [
        'data:image/jpeg;base64,QQ==',
        'data:image/jpeg;base64,Qg==',
      ],
    );
    expect(out, contains('needs_review'));
    expect(captured, isNotNull);
    expect(captured!['model'], 'gpt-4o');
    expect(captured!['response_format'], {'type': 'json_object'});
    final messages = captured!['messages'] as List;
    final content = (messages[1] as Map)['content'] as List;
    expect(content.where((c) => (c as Map)['type'] == 'image_url').length, 2);
    expect(jsonEncode(captured), isNot(contains('sk-live')));
  });

  test('completeWithImageFiles uploads Files then calls Responses with file_id', () async {
    final uploads = <String>[];
    final deletes = <String>[];
    Map<String, dynamic>? responsesBody;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var fileSeq = 0;
    server.listen((req) async {
      final path = req.uri.path;
      if (req.method == 'POST' && path.endsWith('/files')) {
        await req.fold<List<int>>([], (p, c) => p..addAll(c));
        fileSeq++;
        final id = 'file-$fileSeq';
        uploads.add(id);
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'id': id, 'object': 'file'}));
        await req.response.close();
        return;
      }
      if (req.method == 'DELETE' && path.contains('/files/')) {
        deletes.add(path.split('/').last);
        req.response.statusCode = 200;
        req.response.write(jsonEncode({'deleted': true}));
        await req.response.close();
        return;
      }
      if (req.method == 'POST' && path.endsWith('/responses')) {
        final raw = await utf8.decoder.bind(req).join();
        responsesBody = jsonDecode(raw) as Map<String, dynamic>;
        req.response.headers.contentType = ContentType.json;
        req.response.write(
          jsonEncode({
            'output_text':
                '{"verdict":"needs_review","confidence":0.4,"summary":"files ok"}',
          }),
        );
        await req.response.close();
        return;
      }
      req.response.statusCode = 404;
      await req.response.close();
    });

    final client = OpenAiClient(
      apiKey: 'sk-test',
      baseUrl: 'http://127.0.0.1:${server.port}/v1',
    );
    final out = await client.completeWithImageFiles(
      systemPrompt: 'return json',
      userText: '{"checks":["same_building_visual"]}',
      images: [
        OpenAiImageFile(bytes: Uint8List.fromList([1, 2, 3]), filename: 'a.jpg'),
        OpenAiImageFile(bytes: Uint8List.fromList([4, 5, 6]), filename: 'b.jpg'),
      ],
    );
    expect(out, contains('files ok'));
    expect(uploads, ['file-1', 'file-2']);
    expect(deletes, containsAll(['file-1', 'file-2']));
    expect(responsesBody, isNotNull);
    final input = responsesBody!['input'] as List;
    final content = (input.first as Map)['content'] as List;
    final fileParts = content
        .where((c) => (c as Map)['type'] == 'input_image')
        .toList();
    expect(fileParts.length, 2);
    expect((fileParts[0] as Map)['file_id'], 'file-1');
    expect((fileParts[1] as Map)['file_id'], 'file-2');
    final textPart = content.cast<Map>().firstWhere(
      (c) => c['type'] == 'input_text',
    );
    expect(
      (textPart['text'] as String).toLowerCase(),
      contains('json'),
    );
  });

  test('completeWithImageFiles falls back to chat data URLs if Responses fails', () async {
    Map<String, dynamic>? chatBody;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var fileSeq = 0;
    server.listen((req) async {
      final path = req.uri.path;
      if (req.method == 'POST' && path.endsWith('/files')) {
        await req.fold<List<int>>([], (p, c) => p..addAll(c));
        fileSeq++;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'id': 'file-$fileSeq'}));
        await req.response.close();
        return;
      }
      if (req.method == 'DELETE' && path.contains('/files/')) {
        req.response.statusCode = 200;
        await req.response.close();
        return;
      }
      if (req.method == 'POST' && path.endsWith('/responses')) {
        req.response.statusCode = 400;
        req.response.write(jsonEncode({'error': {'message': 'no file_id'}}));
        await req.response.close();
        return;
      }
      if (req.method == 'POST' && path.endsWith('/chat/completions')) {
        final raw = await utf8.decoder.bind(req).join();
        chatBody = jsonDecode(raw) as Map<String, dynamic>;
        req.response.headers.contentType = ContentType.json;
        req.response.write(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content':
                      '{"verdict":"needs_review","confidence":0.1,"summary":"fallback"}',
                },
              },
            ],
          }),
        );
        await req.response.close();
        return;
      }
      req.response.statusCode = 404;
      await req.response.close();
    });

    final client = OpenAiClient(
      apiKey: 'sk-test',
      baseUrl: 'http://127.0.0.1:${server.port}/v1',
    );
    final out = await client.completeWithImageFiles(
      systemPrompt: 'return json',
      userText: '{}',
      images: [
        OpenAiImageFile(bytes: Uint8List.fromList([9]), filename: 'a.png'),
        OpenAiImageFile(bytes: Uint8List.fromList([8]), filename: 'b.png'),
      ],
    );
    expect(out, contains('fallback'));
    expect(chatBody, isNotNull);
    final content =
        ((chatBody!['messages'] as List)[1] as Map)['content'] as List;
    expect(content.where((c) => (c as Map)['type'] == 'image_url').length, 2);
  });
}
