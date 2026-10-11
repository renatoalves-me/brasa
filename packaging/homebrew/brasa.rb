# Homebrew cask for Brasa. It lives in the tap repo renatoalves-me/homebrew-brasa (Casks/brasa.rb).
# After each release, update `version` and `sha256` (the release publishes the .sha256 file).
cask "brasa" do
  version "1.1.0"
  sha256 "REPLACE_WITH_SHA256_OF_THE_RELEASE_ZIP"

  url "https://github.com/renatoalves-me/brasa/releases/download/v#{version}/Brasa-v#{version}-arm64.zip"
  name "Brasa"
  desc "Menu bar temperature monitor for Apple Silicon with status and advice"
  homepage "https://github.com/renatoalves-me/brasa"

  depends_on macos: ">= :sonoma"
  depends_on arch: :arm64

  app "Brasa.app"
  binary "#{appdir}/Brasa.app/Contents/MacOS/Brasa", target: "brasa"

  # The build is ad-hoc signed (not notarized yet): clear the quarantine flag so macOS opens it.
  postflight do
    system_command "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "#{appdir}/Brasa.app"]
  end

  zap trash: "~/Library/Preferences/br.com.renato.brasa.plist"
end
