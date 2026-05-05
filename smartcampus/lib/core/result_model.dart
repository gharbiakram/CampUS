/// Generic result wrapper for success/failure pattern
sealed class Result<T> {
  const Result();

  /// Execute callback if this is a success
  void whenSuccess(void Function(T data) callback) {
    if (this is Success<T>) {
      callback((this as Success<T>).data);
    }
  }

  /// Execute callback if this is a failure
  void whenFailure(void Function(Exception error) callback) {
    if (this is Failure<T>) {
      callback((this as Failure<T>).error);
    }
  }

  /// Transform result with callbacks for both success and failure
  R fold<R>(
    R Function(Exception error) onFailure,
    R Function(T data) onSuccess,
  ) {
    if (this is Failure<T>) {
      return onFailure((this as Failure<T>).error);
    } else if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    }
    throw StateError('Unknown Result type');
  }

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;

  /// Get data if success, null otherwise
  T? getOrNull() {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    return null;
  }
}

/// Success result with data
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);
}

/// Failure result with exception
class Failure<T> extends Result<T> {
  final Exception error;

  const Failure(this.error);
}
