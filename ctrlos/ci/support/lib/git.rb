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
      args << "--remote"
      name = [remote, name].join("/")
    end
    git("branch", *args, "--list", name, get_stdout: true).strip() != ""
  end

  def ensure_remote(name, url)
    begin
      git("remote", "remove", name)
    rescue CommandFailed
      # It's okay if there was nothing to remove.
    end
    git("remote", "add", name, url)
  end

  def fetch(name, refetch: false)
    args = []
    if refetch
      args << "--refetch" if refetch
    end
    git("fetch", *args, name)
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
    git("rev-parse", "HEAD", get_stdout: true).strip()
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

