# Testing

## Python API testing

### Step 1: Build the models

We supply a build script to compile the binaries.  First, set the
paths to CmdStan and BridgeStan, being sure to include a final
backslash (`/`).

```
$ export CMDSTAN=~/github/stan-dev/cmdstan/
$ export BRIDGESTAN=~/gitlab/roualdes/bridgestan/
```

Then change directories to where the tests are and build the Stan
model binaries.

```
$ cd bridgestan/test
$ ./build.sh
```

#### Step 2: Run tests

Run the test script in Python.

```
$ cd bridgestan/test
$ python3 test_bridgestan.py
```

If there are any test failures, they will be printed.




