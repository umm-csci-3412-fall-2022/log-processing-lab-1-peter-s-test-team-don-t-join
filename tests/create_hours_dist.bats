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

  cp -R bin "$BATS_TMPDIR"/bin
  cp -R html_components "$BATS_TMPDIR"/html_components
  cp -R tests "$BATS_TMPDIR"/tests
  mkdir -p "$BATS_TMPDIR"/data/discovery
  mkdir -p "$BATS_TMPDIR"/data/velcro
  tar -zxf log_files/discovery_secure.tgz --directory "$BATS_TMPDIR"/data/discovery
  cp tests/discovery_failed_login_data.txt "$BATS_TMPDIR"/data/discovery/failed_login_data.txt
  tar -zxf log_files/velcro_secure.tgz --directory "$BATS_TMPDIR"/data/velcro
  cp tests/velcro_failed_login_data.txt "$BATS_TMPDIR"/data/velcro/failed_login_data.txt

  # Go into the scratch directory to do all the work.
  cd "$BATS_TMPDIR" || exit 1
}

# Remove the temporary scratch directory to clean up after ourselves.
teardown() {
  temp_del "$BATS_TMPDIR"
}

# If this test fails, your script file doesn't exist, or there's
# a typo in the name, or it's in the wrong directory, etc.
@test "bin/create_hours_dist.sh exists" {
  assert_file_exist "bin/create_hours_dist.sh"
}

# If this test fails, your script isn't executable.
@test "bin/create_hours_dist.sh is executable" {
  assert_file_executable "bin/create_hours_dist.sh"
}

# If this test fails, your script either didn't run at all, or it
# generated some sort of error when it ran.
@test "bin/create_hours_dist.sh runs successfully" {
  run bin/create_hours_dist.sh data
  assert_success
}

# If this test fails, your script didn't generate the correct HTML
# for the bar chart for the hour data from discovery and velcro.
@test "bin/create_hours_dist.sh generates correct simple output" {
  run bin/create_hours_dist.sh data
  run diff -wbB tests/hours_dist.html data/hours_dist.html
  assert_success
}
