cask "pastepal" do
  version "1.0.0"
  sha256 :no_check  # Will be calculated when you have a real download URL

  url "https://github.com/BigVik193/pastepal/releases/download/v#{version}/PastePal-#{version}.zip"
  name "PastePal"
  desc "Advanced clipboard manager for macOS with 10 configurable clipboard slots and keyboard shortcuts"
  homepage "https://pastepal-landing.vercel.app"

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
    "~/Library/Preferences/com.pastepal.app.plist",
    "~/Library/Application Support/PastePal",
  ]
end