"""Drop-in sanity tests for any build123d project with a `parts/` package.

Picks up every public zero-argument function in parts/*.py whose return
annotation is a build123d shape, builds it, and checks it's a valid solid that
survives a STEP round trip. Stray solids from a builder (the classic "Box made
inside a helper silently joined BuildPart") show up as an extra solid.
"""

import importlib
import inspect
import pkgutil
from pathlib import Path

import pytest
from build123d import Compound, Part, Solid, export_step, import_step

import parts

SINGLE_SOLID = (Solid, Part)
SHAPES = (*SINGLE_SOLID, Compound)
STEP_VOLUME_RTOL = 1e-6


def _builders():
    for mod in pkgutil.iter_modules(parts.__path__):
        module = importlib.import_module(f"parts.{mod.name}")
        for name, fn in inspect.getmembers(module, inspect.isfunction):
            if fn.__module__ != module.__name__ or name.startswith("_"):
                continue
            sig = inspect.signature(fn)
            required = [p for p in sig.parameters.values() if p.default is p.empty]
            if not required and sig.return_annotation in SHAPES:
                yield pytest.param(fn, id=f"{mod.name}.{name}")


BUILDERS = list(_builders())


@pytest.mark.parametrize("build", BUILDERS)
def test_valid_solid(build):
    shape = build()
    assert shape.is_valid
    assert shape.volume > 0
    if inspect.signature(build).return_annotation in SINGLE_SOLID:
        bboxes = [s.bounding_box() for s in shape.solids()]
        assert len(bboxes) == 1, f"expected one solid, got {len(bboxes)}: {[(tuple(b.min), tuple(b.max)) for b in bboxes]}"


@pytest.mark.parametrize("build", BUILDERS)
def test_step_roundtrip(build, tmp_path: Path):
    shape = build()
    path = tmp_path / "part.step"
    export_step(shape, path)
    assert import_step(path).volume == pytest.approx(shape.volume, rel=STEP_VOLUME_RTOL)
