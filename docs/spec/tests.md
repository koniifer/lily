# tests

1. tests should attempt to be meaningful in some way, patching targeting bugs, or behaviours.

2. tests should be written as hblang vendored tests. all tests can be run with `HBC_TESTS=1 ./build`. status of failed tests should be emitted to `out/subdir.test-name.test`

3. tests should be written as one of:
    - part of an exhaustive folder covering all aspects of a datastructure / module. e.g:
        ```
        lily/
            some-module/
                func1.hb
                struct/
                    method1.hb
                    method2.hb
            other-module/
                ...
            ...
        lang/
            ...
        ```
    - one-and-done tests for locating bugs (which should be kept after the bug is patched, unless it is made obsolete by an exhaustive test)
