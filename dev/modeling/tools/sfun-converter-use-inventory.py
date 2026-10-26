"""Static single-line macro inventory, not preprocessing or a C semantic parser."""
import re

def inventory(source):
    ends = re.findall(r'^#define ___END_SFUN_(\w+)\([^\n]*?\)([^\n]*)$', source, re.M)
    assert len({name for name, _ in ends}) == len(ends), 'duplicate local macro'
    rows = []
    for name, tail in ends:
        if name.endswith('_TO_SCMOBJ'):
            if tail == '___EXT(___release_scmobj)(s);}': kind = 'native-reference-drop'
            elif tail == '}': kind = 'close-only'
            else: raise AssertionError(('unclassified input cleanup', name, tail))
            direction = 'C-to-Scheme'
        elif name.startswith('SCMOBJ_TO_'):
            assert tail == '', ('unclassified result end', name, tail)
            direction, kind = 'Scheme-to-C', 'empty-end'
        else:
            continue
        begin = '#define ___BEGIN_SFUN_' + name + '('
        assert source.count(begin) == 1, ('missing or duplicate begin', name)
        rows.append(dict(name=name, direction=direction, endEffect=kind, begin=begin,
                         end='#define ___END_SFUN_' + name + '('))
    assert len(rows) == 116
    assert sum(r['direction'] == 'C-to-Scheme' for r in rows) == 58
    assert sum(r['endEffect'] == 'native-reference-drop' for r in rows) == 43
    assert sum(r['endEffect'] == 'close-only' for r in rows) == 15
    assert sum(r['direction'] == 'Scheme-to-C' for r in rows) == 58
    return rows
