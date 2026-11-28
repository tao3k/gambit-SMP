"""Read-only linked-image cuts for the existing source.contract capability.

This checks image identity, actual instruction bytes, direct branch targets and
a narrowly declared caller-stack slot interval. It neither executes the image
nor proves whole-program Scheme reachability or a C/source refinement.
"""
import hashlib
import json
import os
import struct
from pathlib import Path


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def address(value):
    if not isinstance(value, str) or not value.startswith('0x'):
        raise ValueError('explicit hexadecimal image address required')
    return int(value, 16)


def macho(raw):
    if len(raw) < 32:
        raise ValueError('truncated Mach-O header')
    magic, cpu, subtype, kind, count, size, flags, reserved = struct.unpack_from('<8I', raw)
    if magic != 0xfeedfacf or cpu != 0x100000c or kind != 2 or reserved:
        raise ValueError('declared little-endian ARM64 Mach-O executable required')
    end = 32 + size
    if end > len(raw) or count > size // 8:
        raise ValueError('invalid Mach-O load-command extent')
    text, symtab, pos = None, None, 32
    for _ in range(count):
        if pos + 8 > end:
            raise ValueError('truncated Mach-O load command')
        cmd, width = struct.unpack_from('<II', raw, pos)
        if width < 8 or width % 8 or pos + width > end:
            raise ValueError('invalid Mach-O load command')
        if cmd == 0x19:
            if width < 72:
                raise ValueError('truncated Mach-O segment')
            fields = struct.unpack_from('<II16sQQQQiiII', raw, pos)
            sections = fields[-2]
            if 72 + sections * 80 > width:
                raise ValueError('invalid Mach-O section inventory')
            for i in range(sections):
                row = struct.unpack_from('<16s16sQQIIIIIIII', raw, pos + 72 + 80*i)
                if row[0].rstrip(b'\0') == b'__text' and row[1].rstrip(b'\0') == b'__TEXT':
                    if text is not None:
                        raise ValueError('duplicate image text section')
                    text = dict(address=row[2], size=row[3], offset=row[4])
        elif cmd == 2:
            if width != 24 or symtab is not None:
                raise ValueError('unique complete Mach-O symbol table required')
            symtab = struct.unpack_from('<6I', raw, pos)[2:]
        pos += width
    if pos != end or text is None or symtab is None:
        raise ValueError('complete text and symbol inventory required')
    if text['offset'] + text['size'] > len(raw) or text['size'] % 4:
        raise ValueError('image text leaves physical file')
    offset, count, strings, length = symtab
    if offset + 16*count > len(raw) or strings + length > len(raw):
        raise ValueError('image symbols leave physical file')
    symbols = {}
    for i in range(count):
        index, typ, section, desc, value = struct.unpack_from('<IBBHQ', raw, offset + 16*i)
        if typ & 0xe0 or typ & 0x0e != 0x0e or not index:
            continue
        if index >= length:
            raise ValueError('image symbol name leaves string table')
        stop = raw.find(b'\0', strings + index, strings + length)
        if stop < 0:
            raise ValueError('unterminated image symbol')
        name = raw[strings + index:stop].decode('utf-8')
        # Different object files may retain same-named local symbols. Such a
        # name cannot anchor a witness; unrelated duplicates need not deny it.
        if name in symbols and symbols[name] != value:
            symbols[name] = None
        else:
            symbols[name] = value
    return text, symbols


def word_at(raw, text, pc):
    index = pc - text['address']
    if index < 0 or index % 4 or index + 4 > text['size']:
        raise ValueError('instruction leaves image text')
    return struct.unpack_from('<I', raw, text['offset'] + index)[0]


def signed(value, bits):
    return value - (1 << bits) if value & (1 << (bits - 1)) else value


def direct_edge(pc, word):
    if word & 0xfc000000 in (0x14000000, 0x94000000):
        return ('call' if word & 0x80000000 else 'branch',
                pc + 4*signed(word & 0x3ffffff, 26))
    if word & 0xff000010 == 0x54000000 or word & 0x7e000000 == 0x34000000:
        return 'conditional', pc + 4*signed((word >> 5) & 0x7ffff, 19)
    return None


def stack_store(word):
    if word & 0xffc00000 == 0xf9000000 and (word >> 5) & 31 == 31:
        return ((word >> 10) & 0xfff)*8
    return None


def inspect(profile, raw):
    if set(profile) != {'schema', 'image', 'imageSha256', 'scope', 'witnesses', 'edges', 'slots', 'assumptions'}:
        raise ValueError('complete linked-image cut contract required')
    if profile['schema'] != 'gambit.linked-image-cuts.v1' or sha(raw) != profile['imageSha256']:
        raise ValueError('linked image identity differs')
    if (not profile['scope'] or not isinstance(profile['assumptions'], list)
            or not profile['assumptions'] or not all(isinstance(x, str) and x for x in profile['assumptions'])):
        raise ValueError('image cut scope and explicit ABI limits required')
    text, symbols = macho(raw)
    witnesses, covered, ids = [], set(), set()
    for cut in profile['witnesses']:
        if set(cut) != {'id', 'symbol', 'start', 'words', 'purpose'} or cut['id'] in ids:
            raise ValueError('unique complete image byte cut required')
        start = address(cut['start'])
        if symbols.get(cut['symbol']) is None or start < symbols[cut['symbol']]:
            raise ValueError('cut symbol does not precede its instructions')
        # A declared symbol binds its actual address separately from reviewed
        # interior cuts. No nearest-symbol heuristic proves C function extent.
        words = cut['words']
        if not words or any(not isinstance(w, str) or len(w) != 8 for w in words):
            raise ValueError('nonempty exact instruction word inventory required')
        observed = [word_at(raw, text, start + 4*i) for i in range(len(words))]
        if observed != [int(w, 16) for w in words]:
            raise ValueError('linked instruction bytes differ: ' + cut['id'])
        ids.add(cut['id'])
        covered.update(start + 4*i for i in range(len(words)))
        witnesses.append(dict(cut, symbolAddress=hex(symbols[cut['symbol']]),
                              bytesSha256=sha(b''.join(struct.pack('<I', w) for w in observed))))
    if not witnesses:
        raise ValueError('image witness inventory is empty')
    edges = []
    for edge in profile['edges']:
        if set(edge) != {'id', 'from', 'to', 'kind'} or address(edge['from']) not in covered:
            raise ValueError('direct edge requires a byte-bound cut')
        actual = direct_edge(address(edge['from']), word_at(raw, text, address(edge['from'])))
        if actual != (edge['kind'], address(edge['to'])):
            raise ValueError('linked direct edge differs: ' + edge['id'])
        edges.append(edge)
    slots = []
    for slot in profile['slots']:
        if set(slot) != {'id', 'save', 'overwrite', 'offset', 'call', 'return'}:
            raise ValueError('complete caller-stack slot interval required')
        first, last = address(slot['save']), address(slot['overwrite'])
        call, returned = address(slot['call']), address(slot['return'])
        if not first < call < returned <= last or returned != call + 4:
            raise ValueError('ordered save/call/return/overwrite required')
        for pc in range(first, last + 4, 4):
            if pc not in covered:
                raise ValueError('slot interval lacks complete reviewed bytes')
        if any(stack_store(word_at(raw, text, pc)) != slot['offset'] for pc in (first, last)):
            raise ValueError('save/overwrite do not address declared caller-stack slot')
        if direct_edge(call, word_at(raw, text, call)) is None or direct_edge(call, word_at(raw, text, call))[0] != 'call':
            raise ValueError('slot lifetime call is not a direct call')
        for pc in range(first + 4, last, 4):
            word = word_at(raw, text, pc)
            edge = direct_edge(pc, word)
            if edge and edge[0] != 'call':
                raise ValueError('slot lifetime is not the declared straight-line caller cut')
            if word & 0x3f000000 == 0x11000000 and word & 31 == 31:
                raise ValueError('caller cut changes SP')
            if word & 0x0a000000 == 0x08000000 and (word >> 5) & 31 == 31:
                if word & 0xffc00000 not in (0xf9000000, 0xf9400000):
                    raise ValueError('unreviewed SP memory operation in slot interval')
                if stack_store(word) == slot['offset']:
                    raise ValueError('caller-stack slot overwritten before declared end')
        slots.append(dict(slot, status='ABI-conditional-readable-address', isGCRoot=False,
                          oldPointeeDereferenceAuthorized=False))
    return dict(imageSha256=profile['imageSha256'], architecture='Mach-O64/ARM64',
                text=text, witnesses=witnesses, edges=edges, slots=slots,
                scope=profile['scope'], assumptions=profile['assumptions'],
                sourceCorrespondence='UNESTABLISHED', naturalSchemeReachability='UNESTABLISHED',
                executionLaunched=False, sourceRefinementAdmitted=False, runtimeAdmitted=False)


def audit(values, raw, ctx):
    profile_name = values['profile']
    profile = json.loads(raw[profile_name])
    if set(raw) != {profile_name}:
        raise ValueError('exact maintained image-profile source inventory required')
    # Cache artifacts are not repository source aliases. This read-only role
    # binds one immutable, non-executable observation snapshot in the selected
    # task, and never supplies a native runtime/producer artifact.
    from gambit_smp.workspace import bounded, identifier
    task = identifier(os.environ.get('GAMBIT_SMP_TASK_ID', ''))
    name = profile['image']
    if (not isinstance(name, str) or not name.startswith('.cache/tasks/' + task + '/')
            or any(part in ('', '.', '..') for part in name.split('/')) or '\\' in name):
        raise ValueError('image snapshot must belong to the selected task')
    path = bounded(ctx.root, name)
    current = ctx.root
    for part in Path(name).parts:
        current = current / part
        if current.is_symlink():
            raise ValueError('image snapshot cannot use symlink aliases')
    if not path.is_file() or path.stat().st_mode & 0o333:
        raise ValueError('immutable non-executable image observation snapshot required')
    ctx.bind([path])
    ctx.remaining()
    result = inspect(profile, path.read_bytes())
    ctx.bind([path])
    ctx.remaining()
    result['imageArtifact'] = name
    result['profile'] = profile_name
    result['profileSha256'] = sha(raw[profile_name])
    return result
