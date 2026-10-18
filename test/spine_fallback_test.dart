import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:epubx/epubx.dart';
import 'package:test/test.dart';

const _containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf"
              media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''';

const _packageOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
         unique-identifier="book-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="book-id">urn:uuid:spine-fallback-test</dc:identifier>
    <dc:title>Spine Fallback Book</dc:title>
    <dc:creator>Fallback Author</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml"
          media-type="application/xhtml+xml"/>
    <item id="chapter2" href="chapter2.xhtml"
          media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
    <itemref idref="chapter2"/>
  </spine>
</package>
''';

const _chapter1Xhtml = '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><title>Chapter One</title></head>
  <body><h1>Chapter One</h1><p>First chapter body.</p></body>
</html>
''';

const _chapter2Xhtml = '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><title>Chapter Two</title></head>
  <body><h1>Chapter Two</h1><p>Second chapter body.</p></body>
</html>
''';

Archive _buildTestEpubArchive() {
  final archive = Archive();

  void addText(String path, String text) {
    final bytes = utf8.encode(text);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  addText('META-INF/container.xml', _containerXml);
  addText('OEBPS/content.opf', _packageOpf);
  addText('OEBPS/chapter1.xhtml', _chapter1Xhtml);
  addText('OEBPS/chapter2.xhtml', _chapter2Xhtml);

  return archive;
}

void main() {
  late List<int> epubBytes;

  setUp(() {
    epubBytes = ZipEncoder().encode(_buildTestEpubArchive())!;
  });

  test('openBook exposes metadata and chapters from the spine', () async {
    final bookRef = await EpubReader.openBook(epubBytes);

    expect(bookRef.Title, 'Spine Fallback Book');
    expect(bookRef.Author, 'Fallback Author');

    final chapters = await bookRef.getChapters();
    expect(chapters, hasLength(2));
    expect(chapters[0].ContentFileName, 'chapter1.xhtml');
    expect(chapters[1].ContentFileName, 'chapter2.xhtml');

    final spineChapters = await bookRef.getSpineChapters();
    expect(spineChapters, hasLength(2));
    expect(spineChapters[0].ContentFileName, 'chapter1.xhtml');
    expect(spineChapters[1].ContentFileName, 'chapter2.xhtml');

    final firstHtml = await chapters[0].readHtmlContent();
    final secondHtml = await chapters[1].readHtmlContent();
    expect(firstHtml, contains('First chapter body.'));
    expect(secondHtml, contains('Second chapter body.'));
  });

  test('openArchive reads an already decoded archive', () async {
    final archive = ZipDecoder().decodeBytes(epubBytes);
    final bookRef = await EpubReader.openArchive(archive);

    expect(bookRef.Title, 'Spine Fallback Book');
    expect(bookRef.Author, 'Fallback Author');

    final chapters = await bookRef.getChapters();
    expect(chapters, hasLength(2));
  });
}
