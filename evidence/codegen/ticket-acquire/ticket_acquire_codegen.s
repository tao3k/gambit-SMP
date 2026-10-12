	.arch armv8.5-a
	.build_version macos,  26, 0
	.text
	.align	2
	.p2align 5,,15
	.globl _ticket_cursor_read
_ticket_cursor_read:
LFB69:
	add	x2, x0, 8
	mov	x3, 8
	ldaddal	x3, x3, [x2]
	.p2align 5,,15
L2:
	ldr	x2, [x0]
	cmp	x2, x3
	bne	L2
	ldr	x2, [x1]
	mov	x1, 8
	ldaddal	x1, x1, [x0]
	mov	x0, x2
	ret
LFE69:
	.align	2
	.p2align 5,,15
	.globl _ticket_cursor_read_after_barrier
_ticket_cursor_read_after_barrier:
LFB70:
	add	x2, x0, 8
	mov	x3, 8
	ldaddal	x3, x3, [x2]
	.p2align 5,,15
L6:
	ldr	x2, [x0]
	cmp	x2, x3
	bne	L6
	dmb	ish
	ldr	x2, [x1]
	mov	x1, 8
	ldaddal	x1, x1, [x0]
	mov	x0, x2
	ret
LFE70:
	.section __TEXT,__eh_frame,coalesced,no_toc+strip_static_syms+live_support
EH_frame1:
	.set L$set$0,LECIE1-LSCIE1
	.long L$set$0
LSCIE1:
	.long	0
	.byte	0x3
	.ascii "zR\0"
	.uleb128 0x1
	.sleb128 -8
	.uleb128 0x1e
	.uleb128 0x1
	.byte	0x10
	.byte	0xc
	.uleb128 0x1f
	.uleb128 0
	.align	3
LECIE1:
LSFDE1:
	.set L$set$1,LEFDE1-LASFDE1
	.long L$set$1
LASFDE1:
	.long	LASFDE1-EH_frame1
	.quad	LFB69-.
	.set L$set$2,LFE69-LFB69
	.quad L$set$2
	.uleb128 0
	.align	3
LEFDE1:
LSFDE3:
	.set L$set$3,LEFDE3-LASFDE3
	.long L$set$3
LASFDE3:
	.long	LASFDE3-EH_frame1
	.quad	LFB70-.
	.set L$set$4,LFE70-LFB70
	.quad L$set$4
	.uleb128 0
	.align	3
LEFDE3:
	.ident	"GCC: (Homebrew GCC 16.2.0) 16.2.0"
	.subsections_via_symbols
