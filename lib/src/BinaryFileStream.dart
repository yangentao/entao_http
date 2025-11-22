// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:async/async.dart';
//
// extension FileBinaryStreamExt on File {
//   FileBinaryOutputStream openWriteBinary({FileMode mode = FileMode.write}) {
//     RandomAccessFile file = this.openSync(mode: mode);
//     return FileBinaryOutputStream(file);
//   }
// }
//
// class FileBinaryOutputStream extends BaseStreamSink<List<int>> {
//   final RandomAccessFile file;
//
//   FileBinaryOutputStream(this.file);
//
//   @override
//   void onAdd(List<int> data) {
//     file.writeFrom(data);
//   }
//
//   @override
//   FutureOr<void> onClose() async {
//     await file.flush();
//     await file.close();
//   }
//
//   @override
//   void onError(Object error, [StackTrace? stackTrace]) {
//     file.closeSync();
//   }
// }
//
// abstract class BaseStreamSink<T> extends BaseEventSink<T> implements StreamSink<T> {
//   bool _addingStream = false;
//
//   @override
//   Future<void> get done => _closeMemo.future;
//
//   @override
//   Future<void> addStream(Stream<T> stream) {
//     _checkCanAddEvent();
//
//     _addingStream = true;
//     var completer = Completer<void>.sync();
//     stream.listen(onAdd, onError: onError, onDone: () {
//       _addingStream = false;
//       completer.complete();
//     });
//     return completer.future;
//   }
//
//   @override
//   Future<void> close() {
//     if (_addingStream) throw StateError('StreamSink is bound to a stream');
//     return super.close();
//   }
//
//   @override
//   void _checkCanAddEvent() {
//     super._checkCanAddEvent();
//     if (_addingStream) throw StateError('StreamSink is bound to a stream');
//   }
// }
//
// abstract class BaseIOSink extends BaseStreamSink<List<int>> {
//   Encoding encoding;
//
//   BaseIOSink([this.encoding = utf8]);
//
//   Future<void> flush() {
//     if (_addingStream) throw StateError('StreamSink is bound to a stream');
//     if (_closed) return Future.value();
//
//     _addingStream = true;
//     return onFlush().whenComplete(() {
//       _addingStream = false;
//     });
//   }
//
//   Future<void> onFlush();
//
//   void write(Object? object) {
//     var string = object.toString();
//     if (string.isEmpty) return;
//     add(encoding.encode(string));
//   }
//
//   void writeAll(Iterable<Object?> objects, [String separator = '']) {
//     var first = true;
//     for (var object in objects) {
//       if (first) {
//         first = false;
//       } else {
//         write(separator);
//       }
//       write(object);
//     }
//   }
//
//   void writeln([Object? object = '']) {
//     write(object);
//     write('\n');
//   }
//
//   void writeCharCode(int charCode) {
//     write(String.fromCharCode(charCode));
//   }
// }
//
// abstract class BaseEventSink<T> implements EventSink<T> {
//   final _closeMemo = AsyncMemoizer<void>();
//
//   bool get _closed => _closeMemo.hasRun;
//
//   @override
//   void add(T data) {
//     _checkCanAddEvent();
//     onAdd(data);
//   }
//
//   void onAdd(T data);
//
//   @override
//   void addError(Object error, [StackTrace? stackTrace]) {
//     _checkCanAddEvent();
//     onError(error, stackTrace);
//   }
//
//   void onError(Object error, [StackTrace? stackTrace]);
//
//   @override
//   Future<void> close() => _closeMemo.runOnce(onClose);
//
//   FutureOr<void> onClose();
//
//   void _checkCanAddEvent() {
//     if (_closed) throw StateError('Cannot add event after closing');
//   }
// }
