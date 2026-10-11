# Homebrew formula for Brasa. It lives in the tap repo renatoalves-me/homebrew-brasa (Formula/brasa.rb).
# It builds from source on the user's Mac (Homebrew already requires the Command Line Tools), so the app is not
# quarantined and macOS opens it without a notarized build. After each release, update `url` and `sha256`.
class Brasa < Formula
  desc "Menu bar temperature monitor for Apple Silicon that tells you what to do"
  homepage "https://github.com/renatoalves-me/brasa"
  url "https://github.com/renatoalves-me/brasa/archive/refs/tags/v1.1.1.tar.gz"
  sha256 "59782a90f31a7416f4a5b9c87894160d8eaa2c24abcc87e834a61b83c493f21f"
  license "MIT"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  def install
    system "./build.sh", "--no-install"
    prefix.install "build/Brasa.app"
    (bin/"brasa").write <<~SH
      #!/bin/bash
      exec "#{opt_prefix}/Brasa.app/Contents/MacOS/Brasa" "$@"
    SH
  end

  def caveats
    <<~EOS
      To put Brasa in your menu bar (and after every upgrade), run:
        brasa --install
      It copies Brasa.app to ~/Applications and opens it.

      In the terminal: brasa --json, brasa --watch, brasa --serve 9091, brasa --help
    EOS
  end

  test do
    assert_match "Brasa #{version}", shell_output("#{bin}/brasa --version")
  end
end
