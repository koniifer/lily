# tests
tests are written in [src/test](../../src/test/)
1. tests that test the language will be in the [lang](../../src/test/lang) subdirectory 
2. tests that test lily will be in the [lily](../../src/test/lily) subdirectory 
3. all tests should return a `u8` as a status code.
    > follow standard status code practices for value.<br>
    > `0` for success, `1` for error, etc
4. all tests should contain the test specification at the top of the file
    - all test arguments are optional
        > tests with no arguments will always pass
    - delimiting whitespace is optional, provided each test argument is prepended with a newline and a `*`
    - `timeout` is formatted like `0.5s`. if a test exceeds this time, it will fail.
    - `args` are given to the application executable
    - `exit` is the exit status of the program (return code)
5. if test compilation fails, the test will be considered failed

the following are all of the (currently) supported test arguments:
```rust
/*
 * exit: u8
 * args: str
 * stdout: str
 * timeout: time
 */
```
a trivial example test:
```rust
/*
 * timeout: 0.5s
 */

 main := fn(): void {
    // test will fail after 0.5s
    loop {}
 }
 ```