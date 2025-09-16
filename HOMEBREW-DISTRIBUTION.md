# Homebrew Distribution Guide

This guide shows how to distribute PastePal via Homebrew - much simpler than Apple's code signing!

## 🍺 Why Homebrew?

✅ **Free** - No Apple Developer Account needed  
✅ **Simple** - No code signing or notarization  
✅ **Trusted** - Users familiar with `brew install`  
✅ **Updates** - Automatic via `brew upgrade`  
✅ **Professional** - Used by major developer tools  

## 🚀 Quick Distribution

### 1. Build Your App

```bash
# Build the app bundle and ZIP
./build-for-homebrew.sh
```

This creates:
- `build/PastePal.app` - The app bundle
- `release/PastePal-1.0.0.zip` - Release archive

### 2. Create GitHub Release

1. Push your code to GitHub
2. Create a new release (e.g., `v1.0.0`)
3. Upload the ZIP file as a release asset
4. Get the download URL

### 3. Update Cask Formula

Edit `pastepal.rb`:

```ruby
url "https://github.com/BigVik193/pastepal/releases/download/v1.0.0/PastePal-1.0.0.zip"
sha256 "abc123..."  # Calculate with: shasum -a 256 PastePal-1.0.0.zip
```

### 4. Test Installation

```bash
# Test your cask locally
brew install --cask ./pastepal.rb

# Test uninstall
brew uninstall --cask pastepal
```

## 📦 Distribution Options

### Option A: Official Homebrew Cask

Submit to [homebrew-cask](https://github.com/Homebrew/homebrew-cask):

1. Fork the homebrew-cask repository
2. Add your `pastepal.rb` to `Casks/p/pastepal.rb`
3. Submit a pull request
4. Users install with: `brew install --cask pastepal`

**Pros**: Maximum visibility, official distribution  
**Cons**: Review process, naming requirements

### Option B: Your Own Tap

Create your own Homebrew tap:

1. Create repository: `homebrew-tap`
2. Add `pastepal.rb` to root
3. Users add tap: `brew tap BigVik193/tap`
4. Users install: `brew install --cask BigVik193/tap/pastepal`

**Pros**: Full control, faster updates  
**Cons**: Less discovery, users must know your tap

### Option C: Direct Cask File

Distribute the `.rb` file directly:

1. Users download `pastepal.rb`
2. Users run: `brew install --cask ./pastepal.rb`

**Pros**: Immediate distribution  
**Cons**: Not searchable, manual updates

## 🔄 Updating Your App

1. **Build new version**: Update version in `build-for-homebrew.sh`
2. **Create GitHub release**: Upload new ZIP
3. **Update cask**: Change version and SHA256 in `pastepal.rb`
4. **Submit update**: PR to homebrew-cask or push to your tap

## 🧪 Testing

```bash
# Install from local file
brew install --cask ./pastepal.rb

# Check installation
ls /Applications/PastePal.app

# Verify app info
/Applications/PastePal.app/Contents/MacOS/PastePal --version

# Uninstall
brew uninstall --cask pastepal

# Cleanup (removes preferences)
brew uninstall --zap --cask pastepal
```

## 🔧 Cask Features Used

- **Universal binary** support (Intel + Apple Silicon)
- **Minimum macOS version** requirement
- **Post-install message** with setup instructions
- **Clean uninstall** with preference removal
- **Accessibility permission** guidance

## 💡 Pro Tips

1. **Use semantic versioning**: v1.0.0, v1.1.0, etc.
2. **Test on clean system**: Use VM or different Mac
3. **Automate builds**: GitHub Actions can build and create releases
4. **Monitor issues**: Watch for installation problems
5. **Keep cask updated**: Always match your latest release

## 🎯 User Experience

Once set up, users get this simple experience:

```bash
# One command to install
brew install --cask pastepal

# One command to update
brew upgrade pastepal

# One command to uninstall
brew uninstall --cask pastepal
```

No scary security warnings, no complex setup - just works! 🎉