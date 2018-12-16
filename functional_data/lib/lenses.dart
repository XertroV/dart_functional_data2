import 'package:meta/meta.dart';

typedef Getter<S, T> = T Function(S);
typedef Updater<S, T> = S Function(S, T);

class Lens<S, T> {
  final Getter<S, T> get;
  final Updater<S, T> update;

  const Lens(this.get, this.update);

  Lens<S, Q> then<Q>(Lens<T, Q> lens) => Lens<S, Q>(
        (s) => lens.get(get(s)),
        (s, q) => update(s, lens.update(get(s), q)),
  );

  Lens<S, Q> thenWithContext<Q>(Lens<T, Q> Function(S context) lensMaker) => Lens<S, Q>(
        (s) => lensMaker(s).get(get(s)),
        (s, q) => update(s, lensMaker(s).update(get(s), q)),
  );

  S map(T Function(T) f, S s) => update(s, f(get(s)));

  /// Not type safe!
  Lens<S, dynamic> operator >>(Lens<T, dynamic> lens) => then(lens);
}


class List$ {
  static Lens<List<T>, T> atIndex<T>(int i) => Lens<List<T>, T>(
        (s) => s[i],
        (s, t) {
      assert(i >= 0 && i < s.length);
      final newS = List<T>.from(s);
      newS.replaceRange(i, i + 1, [t]);
      return newS;
    },
  );

  static Lens<List<T>, T> where<T>(bool Function(T) predicate) => Lens<List<T>, T>(
        (s) => s.firstWhere(predicate),
        (s, t) {
      final index = s.indexWhere(predicate);
      final newS = List<T>.from(s);
      newS.replaceRange(index, index + 1, [t]);
      return newS;
    },
  );

  static Lens<List<T>, Optional<T>> whereOptional<T>(bool Function(T) predicate) => Lens<List<T>, Optional<T>>(
        (s) => Optional<T>(s.firstWhere(predicate, orElse: () => null)),
        (s, t) {
      if (!t.hasValue) return s;
      final index = s.indexWhere(predicate);
      if (index < 0) return s;
      final newS = List<T>.from(s);
      newS.replaceRange(index, index + 1, [t.raw]);
    },
  );
}

@immutable
class Optional<T> {
  final T raw;

  const Optional(this.raw);

  bool get hasValue => raw != null;
}

// Borrowed from the dart sdk: sdk/lib/math/jenkins_smi_hash.dart.
class Jenkins {
  static int combine(int hash, int hash2) {
    assert(hash2 is! Iterable);
    hash = 0x1fffffff & (hash + hash2);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}