require_relative "common"
require_relative "git"
require_relative "gitlab"

def in_ci?()
  # We are purposefully not using the other CI variables that can be used for local testing purposes.
  # Do not make `in_ci?` true in local dev, and instead prefer checking for the required values or secrets.
  !!ENV["CI_PIPELINE_SOURCE"]
end
