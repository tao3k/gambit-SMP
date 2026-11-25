"""Complete implementation provenance for the Gerbil build capability."""
from pathlib import Path
import hashlib
from gambit_smp.framework import digest


def source_files(package=None):
    """Bind every owned module and the canonical Scheme helper, in stable order."""
    directory = Path(package)/'gerbil_build' if package is not None else Path(__file__).resolve().parent
    return (*sorted(directory.glob('*.py')),
            directory.parent / 'gerbil_compile_products.ss',
            directory.parent / 'gerbil_library_order.ss',
            directory.parent / 'gerbil_semantic_graph.ss',
            directory.parent / 'gerbil_initialization_view.ss',
            directory.parent / 'gerbil_static_products.ss')


def source_identity():
    """Relocation-independent identity of the entire implementation bundle."""
    records = ((path.name, digest(path)) for path in source_files())
    payload = ''.join(name + ':' + sha + '\n' for name, sha in records)
    return hashlib.sha256(payload.encode()).hexdigest()
