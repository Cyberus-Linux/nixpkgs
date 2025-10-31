#!/usr/bin/env nix-shell

#
# This script runs the Linux updater script, then creates the resulting merge request when relevant.
#

# Must be ran from the root of the repository.
#!nix-shell -I nixpkgs=./.
#!nix-shell -p ruby -i ruby
#!nix-shell -p curl

require "uri"
require "json"
require_relative "../support/lib/ci"

# Top-level of the repository.
REPO_ROOT = File.join(__dir__(), "../../..")

# Remote name.
GIT_REMOTE = "gitlab_origin"

# Branch this is running against.
TARGET_BRANCH = ENV["CI_COMMIT_BRANCH"]

# Use a standardized branch name.
BRANCH_NAME = "scheduled/linux-kernels"

# Provided by GitLab in the environment.
CI_SERVER_HOST = ENV["CI_SERVER_HOST"]
CI_PROJECT_PATH = ENV["CI_PROJECT_PATH"]
CI_PROJECT_ID = ENV["CI_PROJECT_ID"]

# Secrets.
SCHEDULED_TASKS_TOKEN = ENV["SCHEDULED_TASKS_TOKEN"]

# Returns true when the API token is available.
# Helper to abstract the implementation detail
def with_secret?()
  !!SCHEDULED_TASKS_TOKEN
end

#
# Job implementation starts here.
#

if in_ci?()
  # Configure git author, only in CI though.
  Git.config("user.email", "automatic-updates@")
  Git.config("user.name", "[Automatic Updates]")
else
  $stderr.puts "Not in CI, not changing git repo configuration..."
end

if with_secret?()
  # This may seem weird, but local dev, even when pushing, shouldn't require token semantics.
  # In other words, the dev could just setup the `gitlab_origin` remote manually for quick tests.
  unless CI_SERVER_HOST && CI_PROJECT_PATH && CI_PROJECT_ID
    $stderr.puts "Error: CI_SERVER_HOST, CI_PROJECT_PATH and CI_PROJECT_ID must be given when a secret is available..."
    $stderr.puts "  CI_SERVER_HOST: #{CI_SERVER_HOST.inspect()}"
    $stderr.puts "  CI_PROJECT_PATH: #{CI_PROJECT_PATH.inspect()}"
    $stderr.puts "  CI_PROJECT_ID: #{CI_PROJECT_ID.inspect()}"
    $stderr.puts "... Aborting!"
    exit 1
  end
  # Ensure remote is setup correctly.
  # (GitLab *can* re-use existing repos in some circumstances.)
  Git.ensure_remote(GIT_REMOTE, "https://gitlab-ci-token:#{SCHEDULED_TASKS_TOKEN}@#{CI_SERVER_HOST}/#{CI_PROJECT_PATH}.git")
else
  if in_ci?()
    $stderr.puts "No secret, yet running in CI? Aborting!"
    exit(1)
  else
    $stderr.puts "No secret configured... will dry-run API and remote configuration..."
  end
end

if Git.branch_exists?(BRANCH_NAME, remote: GIT_REMOTE)
  # Re-use existing branch
  commit = Git.get_remote_commit(GIT_REMOTE, branch: BRANCH_NAME)
  Git.fetch(GIT_REMOTE, commit: commit)
  Git.checkout(commit, name: BRANCH_NAME)
else
  # Otherwise create from the current commit
  Git.checkout(name: BRANCH_NAME)
end

# Keep track of where we started at.
initial_revision = Git.current_commit()
$stderr.puts ":: Started on revision #{initial_revision.inspect}."

# The updater script will automatically commit if the environment variable is set to `1`.
ENV["COMMIT"] = "1"
# We are only maintaining the mainline kernels.
run(File.join(REPO_ROOT, "pkgs/os-specific/linux/kernel/update-mainline.py"))

# Check if anything was done.
final_revision = Git.current_commit()
$stderr.puts ":: Ended on revision #{final_revision.inspect}."

# Nothing was done?
if initial_revision == final_revision
  $stderr.puts " → No changes, nothing left to do."
  exit(0)
end

# Otherwise push the changes
Git.push(GIT_REMOTE, BRANCH_NAME)

#
# Try opening a merge request, or update its description.
#

# Information for the merge request.
title = "Scheduled kernel updates #{Time.new().to_s()}"
description = <<~EOD
Scheduled update for the Linux kernels.

#{Git.git("log", "--format= - %s", "#{initial_revision}..#{final_revision}", get_stdout: true)}

<details>
<summary>Additional context...</summary>

```
CI_JOB_URL = #{ENV["CI_JOB_URL"].inspect()}
```

</details>
EOD

$stderr.puts "========================="
$stderr.puts "Merge request information"
$stderr.puts "========================="
$stderr.puts ""
$stderr.puts "Title:"
$stderr.puts title.gsub(/^/, "# ")
$stderr.puts "Description:"
$stderr.puts description.gsub(/^/, "# ")
$stderr.puts ""
$stderr.puts ""

if merge_request = GitLab.merge_requests(source_branch: BRANCH_NAME, state: "opened").first
  $stderr.puts ":: Updating existing merge request..."
  merge_request["title"] = title
  merge_request["description"] = description
  pp GitLab.update_merge_request(merge_request)
else
  $stderr.puts ":: Creating merge request for update..."
  merge_request = {
    source_branch: BRANCH_NAME,
    target_branch: TARGET_BRANCH,
    title: title,
    description: description,
    allow_collaboration: true,
    remove_source_branch: true,
  }
  pp GitLab.create_merge_request(merge_request)
end
