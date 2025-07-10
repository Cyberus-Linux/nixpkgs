require "shellwords"

class CommandFailed < StandardError
  def initialize(status)
    @status = status
  end

  def exitstatus()
    @status.exitstatus
  end

  def message()
    "Command exited with exit code #{exitstatus}."
  end

  def to_s()
    message
  end

  def inspect()
    "<CommandFailed(#{exitstatus})>"
  end
end

def run(*cmd)
  $stderr.puts " $ #{cmd.shelljoin()}"
  system(*cmd)
    .tap do |result|
      unless $?.success?
        raise CommandFailed.new($?)
      end
    end
end

def slurp(*cmd)
  $stderr.puts " $ #{cmd.shelljoin()}"
  `#{cmd.shelljoin()}`
    .tap do |result|
      unless $?.success?
        raise CommandFailed.new($?)
      end
    end
end
