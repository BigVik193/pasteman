cask "pastepal" do
  version "1.0.2"
  sha256 "1f7ca66973d4f0bef582e391d047579fb50ed728cc944a21521b05b03324fe0d"

  url "https://github.com/BigVik193/pastepal/releases/download/v#{version}/PastePal-#{version}.zip"
  name "PastePal"
  desc "Advanced clipboard manager with 10 configurable slots"
  homepage "https://github.com/BigVik193/pastepal"

  # Minimum macOS version requirement
  depends_on macos: ">= :ventura"

  app "PastePal.app"

  # Post-install message to help users
  postflight do
    puts <<~EOS
      🎉 PastePal installed successfully!

      📋 Quick Start:
      1. Launch PastePal from Applications
      2. Grant accessibility permissions when prompted
      3. Use default shortcuts:
         • Cmd+Shift+[1,2,7,8,9] to save/paste clipboard slots
         • Cmd+Option+Shift+[1,2,7,8,9] to clear slots

      ⚙️  Configure custom shortcuts via menu bar → Settings
      📝 Available keys: E,J,U,X,Y / 0,1,2,7,8,9 / `,],[
      ❓ Get help via menu bar → "How to Use PastePal"

      For support: https://github.com/BigVik193/pastepal/issues
    EOS
  end

  # Clean uninstall
  uninstall quit: "com.pastepal.app"

  zap trash: [
    "~/Library/Application Support/PastePal",
    "~/Library/Preferences/com.pastepal.app.plist",
  ]
end