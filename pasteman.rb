cask "pasteman" do
  version "1.0.2"
  sha256 "1f7ca66973d4f0bef582e391d047579fb50ed728cc944a21521b05b03324fe0d"

  url "https://github.com/BigVik193/pasteman/releases/download/v#{version}/Pasteman-#{version}.zip"
  name "Pasteman"
  desc "Advanced clipboard manager with 10 configurable slots"
  homepage "https://github.com/BigVik193/pasteman"

  # Minimum macOS version requirement
  depends_on macos: ">= :ventura"

  app "Pasteman.app"

  # Post-install message to help users
  postflight do
    puts <<~EOS
      🎉 Pasteman installed successfully!

      📋 Quick Start:
      1. Launch Pasteman from Applications
      2. Grant accessibility permissions when prompted
      3. Use default shortcuts:
         • Cmd+Shift+[1,2,7,8,9] to save/paste clipboard slots
         • Cmd+Option+Shift+[1,2,7,8,9] to clear slots

      ⚙️  Configure custom shortcuts via menu bar → Settings
      📝 Available keys: E,J,U,X,Y / 0,1,2,7,8,9 / `,],[
      ❓ Get help via menu bar → "How to Use Pasteman"

      For support: https://github.com/BigVik193/pasteman/issues
    EOS
  end

  # Clean uninstall
  uninstall quit: "com.pasteman.app"

  zap trash: [
    "~/Library/Application Support/Pasteman",
    "~/Library/Preferences/com.pasteman.app.plist",
  ]
end