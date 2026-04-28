class ClaudeProfileManager < Formula
  desc "Manage multiple Claude Code accounts as profiles, run each session with a different account"
  homepage "https://github.com/USER/claude-profile-manager"
  # url and sha256 must be updated after release
  url "https://github.com/USER/claude-profile-manager/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  def install
    bin.install "src/claude-profile-manager"

    share_dir = share/"claude-profile-manager"
    share_dir.mkpath
    share_dir.install "src/claude-profile-manager.zsh"
    share_dir.install "src/claude-profile-manager.bash"
    share_dir.install "src/statusline-command.sh"
  end

  def caveats
    <<~EOS
      To activate shell integration, add the following to your rc file:

      zsh (~/.zshrc):
        source #{share}/claude-profile-manager/claude-profile-manager.zsh

      bash (~/.bashrc):
        source #{share}/claude-profile-manager/claude-profile-manager.bash

      After setup:
        cpm setup    # initial setup wizard
    EOS
  end

  test do
    assert_match "cpm", shell_output("#{bin}/claude-profile-manager help")
  end
end
