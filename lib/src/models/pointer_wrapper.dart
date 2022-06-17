import 'dart:ffi';

class PointerWrapper implements Finalizable {
  Pointer<Void> ptr;

  PointerWrapper(this.ptr);
}
