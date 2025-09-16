cask "pastepal" do
  version "1.0.2"
  sha256 "7edbc0eda6a26db6c87793a656ad73e25acdba66e8204c97990283340db52765"

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
      ❓ Get help via menu bar → Settings → "How to Use PastePal"

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