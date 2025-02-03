# tests
tests are written in [src/test](../../src/test/)
1. tests that test the language will be in the [lang](../../src/test/lang) subdirectory 
2. tests that test lily will be in the [lily](../../src/test/lily) subdirectory 
3. all tests should return any integer or boolean value.
    > follow standard practices for exit code.<br>
    > `0` for success, `1` for error, etc
4. all tests should contain the test specification at the top of the file
    - all test arguments are optional
        > tests with no arguments will always pas
    - `timeout` is the max length a test can run before failing
    - `args` are given to the application executable
    - `exit` is the exit status of the program (return code)
5. if test compilation fails, the test will be considered failed
6. tests for lily should try to limit the number of unrelated structures/functions tested.
7. tests for lang should be headless (not rely on lily at all)

a trivial example test:
```rust
expected := .{
	exit: 0,
    timeout: 0.5,
    stdout: "",
    args: .[]
}

main := fn(): void {
    // test will fail after 0.5s
    loop {}
}
 ```