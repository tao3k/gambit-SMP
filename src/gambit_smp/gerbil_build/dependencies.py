"""Decode compiler-owned header dependencies for both native consumers."""

from pathlib import Path

def _compiler_dependencies(text, cwd, generated):
    """Decode GCC -MD make syntax without shell expansion or guessed includes."""
    if not isinstance(text, str) or '\0' in text:
        raise ValueError('compiler dependency text required')
    text = text.replace('\\\n', '')
    # One output rule is emitted by this invocation; -MP and arbitrary rules
    # are not part of the managed compiler request.
    if ':' not in text:
        raise ValueError('complete compiler dependency rule required')
    target, body = text.split(':', 1)
    if not target.strip() or ':' in body or '\n' in body.strip():
        raise ValueError('unsupported compiler dependency rule')
    names, word, i = [], '', 0
    while i < len(body):
        ch = body[i]
        if ch == '\\':
            i += 1
            if i == len(body):raise ValueError('incomplete dependency escape')
            word += body[i]
        elif ch == '$':
            if body[i:i+2] != '$$':raise ValueError('dependency expansion is unsupported')
            word += '$';i += 1
        elif ch.isspace():
            if word:names.append(word);word = ''
        elif ch == '#':
            raise ValueError('unescaped dependency comment')
        else:word += ch
        i += 1
    if word:names.append(word)
    if not names:raise ValueError('nonempty dependency closure required')
    generated = Path(generated).resolve()
    paths = []
    for name in names:
        p = Path(name)
        if not p.is_absolute():p = Path(cwd)/p
        p = p.resolve()
        if p == generated:continue  # Recreated by the identity-bound GSC input.
        if not p.is_file():raise ValueError('compiler dependency unavailable: '+str(p))
        if p not in paths:paths.append(p)
    if not paths:raise ValueError('compiler reported no retained header dependency')
    return paths

