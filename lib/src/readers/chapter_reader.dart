import 'package:collection/collection.dart' show IterableExtension;

import '../ref_entities/epub_book_ref.dart';
import '../ref_entities/epub_chapter_ref.dart';
import '../ref_entities/epub_text_content_file_ref.dart';
import '../schema/navigation/epub_navigation_point.dart';

class ChapterReader {
  static List<EpubChapterRef> getChapters(EpubBookRef bookRef) {
    final navigationPoints = bookRef.Schema?.Navigation?.NavMap?.Points;
    if (navigationPoints == null || navigationPoints.isEmpty) {
      return getChaptersFromSpine(bookRef);
    }
    return getChaptersImpl(bookRef, navigationPoints);
  }

  /// Builds chapter refs from the package spine when the EPUB has no
  /// navigation document (or an empty navigation map).
  static List<EpubChapterRef> getChaptersFromSpine(EpubBookRef bookRef) {
    var result = <EpubChapterRef>[];

    final spineItems = bookRef.Schema?.Package?.Spine?.Items;
    final manifestItems = bookRef.Schema?.Package?.Manifest?.Items;
    final htmlContentFiles = bookRef.Content?.Html;
    if (spineItems == null ||
        manifestItems == null ||
        htmlContentFiles == null) {
      return result;
    }

    for (var spineItem in spineItems) {
      final idRef = spineItem.IdRef;
      if (idRef == null || idRef.isEmpty) continue;

      final manifestItem = manifestItems.firstWhereOrNull(
        (item) =>
            item.Id != null && item.Id!.toLowerCase() == idRef.toLowerCase(),
      );
      if (manifestItem == null) continue;

      final href = manifestItem.Href;
      if (href == null || href.isEmpty) continue;

      final decodedHref = Uri.decodeFull(href);
      final contentFileRef =
          htmlContentFiles[href] ?? htmlContentFiles[decodedHref];
      if (contentFileRef == null) continue;

      var chapterRef = EpubChapterRef(contentFileRef);
      chapterRef.ContentFileName = contentFileRef.FileName ?? decodedHref;
      chapterRef.Anchor = null;
      chapterRef.Title = '';
      chapterRef.SubChapters = <EpubChapterRef>[];
      result.add(chapterRef);
    }

    return result;
  }

  static List<EpubChapterRef> getChaptersImpl(
    EpubBookRef bookRef,
    List<EpubNavigationPoint> navigationPoints,
  ) {
    var result = <EpubChapterRef>[];
    // navigationPoints.forEach((EpubNavigationPoint navigationPoint) {
    for (var navigationPoint in navigationPoints) {
      String? contentFileName;
      String? anchor;
      if (navigationPoint.Content?.Source == null) continue;
      var contentSourceAnchorCharIndex = navigationPoint.Content!.Source!
          .indexOf('#');
      if (contentSourceAnchorCharIndex == -1) {
        contentFileName = navigationPoint.Content!.Source;
        anchor = null;
      } else {
        contentFileName = navigationPoint.Content!.Source!.substring(
          0,
          contentSourceAnchorCharIndex,
        );
        anchor = navigationPoint.Content!.Source!.substring(
          contentSourceAnchorCharIndex + 1,
        );
      }
      contentFileName = Uri.decodeFull(contentFileName!);
      EpubTextContentFileRef? htmlContentFileRef;
      if (!bookRef.Content!.Html!.containsKey(contentFileName)) {
        throw Exception(
          'Incorrect EPUB manifest: item with href = \"$contentFileName\" is missing.',
        );
      }

      htmlContentFileRef = bookRef.Content!.Html![contentFileName];
      var chapterRef = EpubChapterRef(htmlContentFileRef);
      chapterRef.ContentFileName = contentFileName;
      chapterRef.Anchor = anchor;
      chapterRef.Title = navigationPoint.NavigationLabels!.first.Text;
      chapterRef.SubChapters = getChaptersImpl(
        bookRef,
        navigationPoint.ChildNavigationPoints!,
      );

      result.add(chapterRef);
    }
    return result;
  }
}
