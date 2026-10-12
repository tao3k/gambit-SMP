#define ___ERR_CODE int

#define ___ERR_CODE_FACILITY_SYSTEM   448
#define ___ERR_CODE_FACILITY_MACOS    384
#define ___ERR_CODE_FACILITY_ERRNO    320
#define ___ERR_CODE_FACILITY_H_ERRNO  319
#define ___ERR_CODE_FACILITY_GAI_CODE 318
#define ___ERR_CODE_FACILITY_TLS      317

#define ___ERR_CODE_BUILD(facility,code) \
(~___MASK(___ERR_CODE,29)+(___CAST(___ERR_CODE,facility)<<16)+(code))

#define ___ERR_CODE_FACILITY(err)(((err)>>16)&___MASK(___ERR_CODE,9))

#define ___HRESULT_ERR(hresult) \
(((hresult)&___MASK(___ERR_CODE,25)) | \
(((hresult)&~___MASK(___ERR_CODE,27))>>2))

#define ___HRESULT_FROM_ERR_CODE(err) \
(((err)&___MASK(___ERR_CODE,25)) | \
(((err)&~___MASK(unsigned ___ERR_CODE,25))<<2))

#define ___WIN32_ERR(win32err) \
___HRESULT_ERR(HRESULT_FROM_WIN32(win32err))

#define ___WIN32_FROM_ERR_CODE(err) \
HRESULT_CODE(___HRESULT_FROM_ERR_CODE(err))

#define ___MACOS_ERR(oserr) \
((oserr)==0?___NO_ERR:___ERR_CODE_BUILD(___ERR_CODE_FACILITY_MACOS,oserr))

#define ___MACOS_FROM_ERR_CODE(err) \
((err)==___NO_ERR?0:((err)-___ERR_CODE_BUILD(___ERR_CODE_FACILITY_MACOS,0)))

#define ___ERRNO_ERR(errno) \
((errno)==0?___NO_ERR:___ERR_CODE_BUILD(___ERR_CODE_FACILITY_ERRNO,errno))

#define ___ERRNO_FROM_ERR_CODE(err) \
((err)==___NO_ERR?0:((err)-___ERR_CODE_BUILD(___ERR_CODE_FACILITY_ERRNO,0)))

#define ___H_ERRNO_ERR(h_errno) \
((h_errno)==0?___NO_ERR:___ERR_CODE_BUILD(___ERR_CODE_FACILITY_H_ERRNO,(h_errno)))

#define ___H_ERRNO_FROM_ERR_CODE(err) \
((err)==___NO_ERR?0:((err)-___ERR_CODE_BUILD(___ERR_CODE_FACILITY_H_ERRNO,0)))

#define ___GAI_CODE_ERR(gai_code) \
((gai_code)==0?___NO_ERR:___ERR_CODE_BUILD(___ERR_CODE_FACILITY_GAI_CODE,(gai_code)))

#define ___GAI_CODE_FROM_ERR_CODE(err) \
((err)==___NO_ERR?0:((err)-___ERR_CODE_BUILD(___ERR_CODE_FACILITY_GAI_CODE,0)))

#define ___ERR_BASE ___ERR_CODE_BUILD(___ERR_CODE_FACILITY_SYSTEM,0)

#define ___NO_ERR                               0
#define ___UNWIND_C_STACK                       (___ERR_BASE+0)
#define ___SFUN_HEAP_OVERFLOW_ERR               (___ERR_BASE+1)
#define ___IMPL_LIMIT_ERR                       (___ERR_BASE+2)
#define ___UNKNOWN_ERR                          (___ERR_BASE+3)
#define ___UNIMPL_ERR                           (___ERR_BASE+4)
#define ___HEAP_OVERFLOW_ERR                    (___ERR_BASE+5)
#define ___CLOSED_DEVICE_ERR                    (___ERR_BASE+6)
#define ___INVALID_OP_ERR                       (___ERR_BASE+7)

