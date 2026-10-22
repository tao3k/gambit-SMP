;;; Loaded before the original test. Only startup allocates Scheme objects.
(declare (standard-bindings) (extended-bindings) (block))
(c-declare #<<c-end
#include <stdint.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>

static int smp_gc_fd = -1;
static struct sockaddr_in smp_gc_sink;
static unsigned char smp_gc_nonce[16];
static unsigned long long smp_gc_sequence = 0;
#if __GCC_ATOMIC_LLONG_LOCK_FREE != 2 || __GCC_ATOMIC_INT_LOCK_FREE != 2
#error "Observer requires always-lock-free native counters and publication"
#endif
typedef char smp_gc_counter_width[sizeof(unsigned long long) == 8 ? 1 : -1];

static int smp_gc_hex(int ch) {
  if (ch >= '0' && ch <= '9') return ch - '0';
  if (ch >= 'a' && ch <= 'f') return ch - 'a' + 10;
  return -1;
}

/* Single startup caller, before registering the callback or loading the test. */
static int smp_gc_start(int port, const char *nonce) {
  int fd, flags, i;
  if (smp_gc_fd >= 0 || port < 1 || port > 65535 || strlen(nonce) != 32)
    return 0;
  for (i = 0; i < 16; ++i) {
    int a = smp_gc_hex(nonce[2*i]), b = smp_gc_hex(nonce[2*i+1]);
    if (a < 0 || b < 0) return 0;
    smp_gc_nonce[i] = (unsigned char)((a << 4) | b);
  }
  fd = socket(AF_INET, SOCK_DGRAM, 0);
  if (fd < 0) return 0;
  flags = fcntl(fd, F_GETFL);
  if (flags < 0 || fcntl(fd, F_SETFL, flags | O_NONBLOCK) < 0) {
    close(fd);
    return 0;
  }
  memset(&smp_gc_sink, 0, sizeof(smp_gc_sink));
  smp_gc_sink.sin_family = AF_INET;
  smp_gc_sink.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  smp_gc_sink.sin_port = htons((unsigned short)port);
  __atomic_store_n(&smp_gc_fd, fd, __ATOMIC_RELEASE);
  return 1;
}

static void smp_gc_put64(unsigned char *p, uint64_t n) {
  int i;
  for (i = 7; i >= 0; --i) { p[i] = (unsigned char)n; n >>= 8; }
}

/* No Scheme allocation, ports, formatting, blocking descriptor or retry loop. */
static void smp_gc_note(void) {
  unsigned char packet[40];
  unsigned long long before;
  int saved_errno = errno;
  int fd = __atomic_load_n(&smp_gc_fd, __ATOMIC_ACQUIRE);
  if (fd < 0) return;
  before = __atomic_load_n(&smp_gc_sequence, __ATOMIC_RELAXED);
  if (before == UINT64_MAX ||
      !__atomic_compare_exchange_n(&smp_gc_sequence, &before, before + 1, 0,
                                  __ATOMIC_RELAXED, __ATOMIC_RELAXED))
    return;
  memcpy(packet, "SMPGC001", 8);
  memcpy(packet + 8, smp_gc_nonce, 16);
  smp_gc_put64(packet + 24, (uint64_t)getpid());
  smp_gc_put64(packet + 32, (uint64_t)(before + 1));
  /* Loss/EINTR/EAGAIN omits evidence. A later cursor can safely skip values. */
  (void)sendto(fd, packet, sizeof(packet), 0,
               (const struct sockaddr *)&smp_gc_sink, sizeof(smp_gc_sink));
  errno = saved_errno;
}
c-end
)

(define smp-gc-datagram-start
  (c-lambda (int char-string) bool "smp_gc_start"))

(define smp-gc-datagram-note!
  (c-lambda () void "smp_gc_note"))

(define (smp-enable-gc-datagram! port nonce)
  (if (smp-gc-datagram-start port nonce)
      (begin
        (##add-gc-interrupt-job! smp-gc-datagram-note!)
        #t)
      #f))

;;; Diagnostic process only: direct calls here are NOT GC-completion evidence.
(define (smp-gc-datagram-allocation-control count)
  (let ((samples (##make-f64vector 2 0.0)))
    (##get-bytes-allocated! samples 0)
    (let loop ((n count))
      (if (##fx> n 0)
          (begin (smp-gc-datagram-note!) (loop (##fx- n 1)))))
    (##get-bytes-allocated! samples 1)
    (##fl= (##f64vector-ref samples 0) (##f64vector-ref samples 1))))
