import 'package:plannerop/core/model/incapacity.dart';

IncapacityType mapApiToType(String apiType) {
  switch (apiType) {
    case 'INITIAL':
      return IncapacityType.INITIAL;
    case 'EXTENSION':
      return IncapacityType.EXTENSION;
    default:
      return IncapacityType.INITIAL;
  }
}

IncapacityCause mapApiToCause(String apiCause) {
  switch (apiCause) {
    case 'LABOR':
      return IncapacityCause.LABOR;
    case 'TRANSIT':
      return IncapacityCause.TRANSIT;
    case 'DISEASE':
      return IncapacityCause.DISEASE;
    default:
      return IncapacityCause.DISEASE;
  }
}
