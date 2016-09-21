#include <unicode/ucnv.h>

U_CAPI void    U_EXPORT2 ucnv_setToUCallBack_51 (UConverter * converter,
                            UConverterToUCallback newAction,
                            const void* newContext,
                            UConverterToUCallback *oldAction,
                            const void** oldContext,
                            UErrorCode * err) {
  ucnv_setToUCallBack(converter, newAction, newContext,
        oldAction, oldContext, err);
}

U_CAPI void  U_EXPORT2 ucnv_close_51 (UConverter * converter) {
  ucnv_close (converter);
}

U_CAPI void  U_EXPORT2
ucnv_setFromUCallBack_51 (UConverter * converter,
                            UConverterFromUCallback newAction,
                            const void* newContext,
                            UConverterFromUCallback *oldAction,
                            const void** oldContext,
                            UErrorCode * err) {

  ucnv_setFromUCallBack(converter, newAction, newContext, oldAction,
        oldContext, err);
}

U_CAPI void U_EXPORT2
ucnv_convertEx_51 (UConverter *targetCnv, UConverter *sourceCnv,
               char **target, const char *targetLimit,
               const char **source, const char *sourceLimit,
               UChar *pivotStart, UChar **pivotSource,
               UChar **pivotTarget, const UChar *pivotLimit,
               UBool reset, UBool flush,
               UErrorCode *pErrorCode) {
  ucnv_convertEx(targetCnv, sourceCnv, target, targetLimit, source,
        sourceLimit, pivotStart, pivotSource,
        pivotTarget, pivotLimit, reset, flush,
        pErrorCode);
}

U_CAPI UConverter* U_EXPORT2
ucnv_open_51 (const char *name,
                       UErrorCode * err) {
  return ucnv_open(name, err);
}

U_STABLE void U_EXPORT2 UCNV_FROM_U_CALLBACK_STOP_51 (
                  const void *context,
                  UConverterFromUnicodeArgs *fromUArgs,
                  const UChar* codeUnits,
                  int32_t length,
                  UChar32 codePoint,
                  UConverterCallbackReason reason,
                  UErrorCode * err) {
  return UCNV_FROM_U_CALLBACK_STOP(context, fromUArgs, codeUnits,
      length, codePoint, reason, err);
}

U_STABLE void U_EXPORT2 UCNV_TO_U_CALLBACK_STOP_51 (
                  const void *context,
                  UConverterToUnicodeArgs *toUArgs,
                  const char* codeUnits,
                  int32_t length,
                  UConverterCallbackReason reason,
                  UErrorCode * err) {
  return UCNV_TO_U_CALLBACK_STOP(context, toUArgs, codeUnits, length,
      reason, err);
}
