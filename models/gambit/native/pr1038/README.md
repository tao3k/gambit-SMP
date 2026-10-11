# PR1038 Reference Fixture

`serialization.scm` is the unchanged upstream fixture from
https://github.com/gambit/gambit/pull/1038 at head
`7e1ae2a5b1b65b3d917e9be9565c9cf969ff4b3f`.

Original path: `tests/unit-tests/10-tables/serialization.scm`.
Git blob: `9522db3af90e5c9a841a1ab80e6896862bce8cc0`.
The framework unit test binds its exact bytes to the cached public snapshot.
Use `native_suite.py --extra-fixture` to copy it into an isolated upstream test
tree, with that tree's original `#.scm` support files. Do not treat it as a
standalone script or edit the upstream candidate's test tree to run it.

The fixture remains upstream source material under Gambit's applicable license;
it is not a newly authored collector repair or whole-SMP acceptance suite.
