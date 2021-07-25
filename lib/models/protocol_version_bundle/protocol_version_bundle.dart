import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'protocol_version_bundle.freezed.dart';

/// Each protocol version consists of three files stored together as a 'bundle':
/// 1) [Protocol-Name.pdf], which is the actual pdf that is displayed
/// 2) [Protocol-Name.json], which holds all content of text per page
/// 3) [Protocol-Name-toc.json], which holds titles of each page and custom colors
///
/// Each 'bundle' of files may be found in one of the following locations:
/// A) As Assets, so that the PDF is available on first load of the app, regardless of internet access
/// B) As Firebase References, which may be downloaded/deleted as desired
/// C) As Files, which is the common pool to which A) and B) are downloaded/accessed in the app

@freezed
class ProtocolVersionBundle with _$ProtocolVersionBundle {
  // shown on first load
  const factory ProtocolVersionBundle.asAssets(
    String bundleId,
    int bundleVersion,
    String pdfAssetPath,
    String jsonAssetPath,
    String tocJsonAssetPath,
  ) = ProtocolVersionBundleAsAssets;

  // available on Firebase Storage for download
  const factory ProtocolVersionBundle.asFirebaseRefs(
    String bundleId,
    int bundleVersion,
    Reference pdfRef,
    Reference jsonRef,
    Reference tocJsonRef,
  ) = ProtocolVersionBundleAsFirebaseRefs;

  // stored locally, all PDFs are loaded from this data model
  const factory ProtocolVersionBundle.asFiles(
    String bundleId,
    int bundleVersion,
    File pdfFile,
    File jsonFile,
    File tocJsonFile,
  ) = ProtocolVersionBundleAsFiles;

  const factory ProtocolVersionBundle.loading() = ProtocolVersionBundleLoading;
  const factory ProtocolVersionBundle.error(
      Object error, StackTrace stackTrace) = ProtocolVersionBundleError;
}