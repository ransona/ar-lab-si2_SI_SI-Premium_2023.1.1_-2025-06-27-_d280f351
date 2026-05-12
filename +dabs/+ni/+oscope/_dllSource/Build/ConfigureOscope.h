#include "extcode.h"
#ifdef __cplusplus
extern "C" {
#endif

/*!
 * Configures device parameters for an NI 5170/5171
 */
int32_t __cdecl startSession(char deviceAddress[], char bitfilePath[]);
/*!
 * Configures device parameters for an NI 5170/5171
 */
uint32_t __cdecl clearOverload(void);
/*!
 * Configures device parameters for an NI 5170/5171
 */
int32_t __cdecl configureChannel(uint32_t channel, double inputRangeVpp, 
	LVBoolean enableFilter, LVBoolean acCoupling);
/*!
 * Configures device parameters for an NI 5170/5171
 */
int32_t __cdecl configureChannels(int32_t nChannels, double inputRangeVpp, 
	LVBoolean enableFilter, LVBoolean acCoupling);
/*!
 * Configures device parameters for an NI 5170/5171
 */
int32_t __cdecl configureSampleClock(LVBoolean enableExternalClock, 
	double externalClockRateHz);
/*!
 * Configures device parameters for an NI 5170/5171
 */
uint8_t __cdecl sessionActive(void);
/*!
 * Configures device parameters for an NI 5170/5171
 */
int32_t __cdecl checkOverload(void);

MgErr __cdecl LVDLLStatus(char *errStr, int errStrLen, void *module);

#ifdef __cplusplus
} // extern "C"
#endif

