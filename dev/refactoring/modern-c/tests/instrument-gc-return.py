"""Instrument the generated internal-return handoff, preserving the target."""
from pathlib import Path
import sys


def instrument(source: str) -> str:
    header = '#include "gambit.h"'
    handoff = '   ___COVER_INTERNAL_RETURN_HANDLER_END;\n\n   ___JUMPEXTPRM(___NOTHING,ira)'
    if source.count(header) != 1 or source.count(handoff) != 1:
        raise ValueError("Generated internal-return anchors changed")
    return source.replace(
        header, header + "\nextern void dev_gc_return_target(___SCMOBJ ira);"
    ).replace(
        handoff, handoff.replace("   ___JUMPEXTPRM", "   dev_gc_return_target(ira);\n   ___JUMPEXTPRM")
    )


if __name__ == "__main__":
    Path(sys.argv[2]).write_text(instrument(Path(sys.argv[1]).read_text()))
