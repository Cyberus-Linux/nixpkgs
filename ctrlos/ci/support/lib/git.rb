module Git
  extend self

  def git(*args, get_stdout: false)
    args = ["git", *args]

    if get_stdout
      slurp(*args)
    else
      run(*args)
    end
  end

  def config(*args)
    git("config", *args)
  end

  def branch_exists?(name, remote: nil)
    args = []
    if remote
      args << "--branches"
      args << remote
      args << ["refs/heads", name].join("/")
      git("ls-remote", *args, get_stdout: true).strip() != ""
    else
      git("branch", *args, "--list", name, get_stdout: true).strip() != ""
    end
  end

  def ensure_remote(name, url)
    begin
      git("remote", "remove", name)
    rescue CommandFailed
      # It's okay if there was nothing to remove.
    end
    git("remote", "add", name, url)
  end

  def get_remote_commit(remote, branch: nil)
    args = []
    if branch
      args << "--branches"
      args << remote
      args << ["refs/heads", branch].join("/")
    else
      # We may want to support non-branches at some point.
      raise "branch needs to be given to `get_remote_commit`"
    end
    git("ls-remote", *args, get_stdout: true)
      .split("\n", 2).first.split(/\s/, 2).first
  end

  def fetch(name, refetch: false, commit: nil)
    args = []
    if refetch
      args << "--refetch" if refetch
    end
    if commit
      args << "--depth=1"
    end
    args << name
    if commit
      args << commit
    end
    git("fetch", *args)
  end

  # Checkout `branch`, optionally creating a new one with the `name`.
  def checkout(branch = nil, name:)
    args = []
    if branch
      args << branch
    end
    if name
      args << "-B"
      args << name
    end
    git("checkout", *args)
  end

  def current_commit()
    revision_for("HEAD")
  end

  def revision_for(ref)
    git("rev-parse", ref, get_stdout: true).strip()
  end

  # Contrary to `git push`, this requires the remote branch name to be given.
  def push(remote, branch, head: branch)
    git("push", remote, [head, branch].join(":"))
  end

  def add(*files)
    git("add", *files)
  end

  def commit(message)
    git("commit", "-m", message)
  end
end

