"""Typed Unicode output audit; no runtime, GC or performance admission."""
import hashlib
import struct


LIMIT = 0x110000
RECORD = struct.Struct("<IBBIIII")


def scalar(code):
    return 0 <= code < LIMIT and not 0xD800 <= code < 0xE000


def validate_shard(data, start, end):
    if not 0 <= start <= end <= LIMIT:
        raise ValueError("invalid Unicode scalar domain")
    expected = (end - start) - max(0, min(end, 0xE000) - max(start, 0xD800))
    if len(data) != expected * RECORD.size:
        raise ValueError("incomplete Unicode record bytes")
    code = start
    for row in RECORD.iter_unpack(data):
        if 0xD800 <= code < 0xE000:
            code = 0xE000
        actual, flags, digit, *mappings = row
        if actual != code:
            raise ValueError("Unicode scalar inventory mismatch")
        if flags > 31 or digit not in (*range(10), 255):
            raise ValueError("invalid Unicode classification field")
        if any(not scalar(value) for value in mappings):
            raise ValueError("Unicode mapping is not a scalar")
        code += 1
    if 0xD800 <= code < min(end, 0xE000):
        code = min(end, 0xE000)
    if code != end:
        raise ValueError("incomplete Unicode scalar inventory")
    return expected


def validate(records, processors):
    if type(processors) is not int or processors <= 0:
        raise ValueError("positive observed processor population required")
    if set(records) != {f"{i}.bin" for i in range(processors)}:
        raise ValueError("incomplete Unicode shard inventory")
    result, count = hashlib.sha256(), 0
    for i in range(processors):
        data = records[f"{i}.bin"]
        count += validate_shard(data, i * LIMIT // processors, (i + 1) * LIMIT // processors)
        result.update(data)
    return {"records": count, "bytes": count * RECORD.size, "semanticSha256": result.hexdigest()}


def compare(left, right, processors):
    first, second = validate(left, processors), validate(right, processors)
    if first != second:
        raise ValueError("Unicode scalar semantics differ")
    return first
