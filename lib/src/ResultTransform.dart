import 'package:entao_dutil/entao_dutil.dart';
import 'package:entao_result/entao_result.dart';

extension on Success {
  R transform<R, T>(R Function(T) maper) {
    if (this case Success(value: T v)) {
      return maper(v);
    }
    errorHare("Bad type");
  }
}
