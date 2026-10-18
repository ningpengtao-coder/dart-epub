import 'package:image/image.dart';
import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_chapter.dart';
import 'epub_content.dart';
import 'epub_schema.dart';

class EpubBook {
  String? Title;
  String? Author;
  List<String?>? AuthorList;
  EpubSchema? Schema;
  EpubContent? Content;
  Image? CoverImage;
  List<EpubChapter>? Chapters;

  @override
  int get hashCode {
    var objects = [
      Title.hashCode,
      Author.hashCode,
      Schema.hashCode,
      Content.hashCode,
      ...CoverImage?.getBytes().map((byte) => byte.hashCode) ?? [0],
      ...AuthorList?.map((author) => author.hashCode) ?? [0],
      ...Chapters?.map((chapter) => chapter.hashCode) ?? [0],
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (!(other is EpubBook)) {
      return false;
    }

    final coverImage = CoverImage;
    final otherCoverImage = other.CoverImage;
    final coverImageEquals = coverImage == null
        ? otherCoverImage == null
        : otherCoverImage != null &&
              collections.listsEqual(
                coverImage.getBytes(),
                otherCoverImage.getBytes(),
              );

    return Title == other.Title &&
        Author == other.Author &&
        collections.listsEqual(AuthorList, other.AuthorList) &&
        Schema == other.Schema &&
        Content == other.Content &&
        coverImageEquals &&
        collections.listsEqual(Chapters, other.Chapters);
  }
}
