#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'

setup() {
  # Create a temporary scratch directory for the shell script to work in.
  BATS_TMPDIR=$(temp_make)

  # The comments below disable a shellcheck warning that would
  # otherwise appear on both these saying that these variables
  # appear to be unused. They *are* used, but in the bats-file
  # code, so shellcheck can't tell they're being used, which is
  # why I'm ignoring those checks for these two variables, and
  # BATSLIB_TEMP_PRESERVE_ON_FAILURE a little farther down.
  # shellcheck disable=SC2034
  BATSLIB_FILE_PATH_REM="#${BATS_TMPDIR}"
  # shellcheck disable=SC2034
  BATSLIB_FILE_PATH_ADD='<temp>'

  # Comment out the next line if you want to see where the temp files
  # are being created.
  echo "Bats temp directory: $BATS_TMPDIR"

  # This tells bats to preserve (i.e., not delete)
  # the temp files generated for failing tests. This might be 
  # useful in trying to figure out what happened when a test fails.
  # It also could potentially clutter up the drive with a bunch
  # of temp files, so you might want to disable it when you're not
  # in "full-on debugging" mode.
  # shellcheck disable=SC2034
  BATSLIB_TEMP_PRESERVE_ON_FAILURE=1

  # Setup the test specific files.
  cp -R bin "$BATS_TMPDIR"/bin
  cp -R tests "$BATS_TMPDIR"/tests
  mkdir -p "$BATS_TMPDIR"/data/discovery
  tar -zxf log_files/discovery_secure.tgz --directory "$BATS_TMPDIR"/data/discovery
  cd "$BATS_TMPDIR" || exit 1
}

# Remove the temporary scratch directory to clean up after ourselves.
teardown() {
  temp_del "$BATS_TMPDIR"
}

# If this test fails, your script file doesn't exist, or there's
# a typo in the name, or it's in the wrong directory, etc.
@test "bin/process_client_logs.sh exists" {
  assert_file_exist "bin/process_client_logs.sh"
}

# If this test fails, your script isn't executable.
@test "bin/process_client_logs.sh is executable" {
  assert_file_executable "bin/process_client_logs.sh"
}

# If this test fails, your script either didn't run at all, or it
# generated some sort of error when it ran.
@test "bin/process_client_logs.sh runs successfully" {
  run bin/process_client_logs.sh data/discovery
  assert_success
}

# If this test fails, your script didn't generate the correct output
# for the logs for discovery.
@test "bin/process_client_logs.sh generates correct simple output" {
  bin/process_client_logs.sh data/discovery
  sort data/discovery/failed_login_data.txt > data/discovery_sorted.txt
  sort tests/discovery_failed_login_data.txt > data/target_sorted.txt
  run diff -wbB data/target_sorted.txt data/discovery_sorted.txt
  assert_success
}
