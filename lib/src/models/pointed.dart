import 'dart:async';
import 'dart:ffi';

abstract class Pointed {
  Future<Pointer<Void>> clonePtr();

  Future<void> freePtr();
}
