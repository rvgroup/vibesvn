# VibeSVN 🦋

Modern SVN client with intuitive interface for macOS, Windows, and Linux.

## ✨ Features

### 🔄 Repository Management
- **📁 Repository Management** - add, remove, clone SVN repositories
- **🔍 Auto Discovery** - working copies and their statuses
- **📊 Revision Tracking** - current revision for each repository
- **⚡ Quick Access** - instant navigation to folders and files

### 📝 Commit Management
- **📋 File Management** - select files for commit with checkboxes
- **📝 Commit History** - quick templates and message history
- **🎨 Smart Templates** - ready templates for different commit types
- **🔒 Credential Storage** - secure storage of logins and passwords
- **🔄 File Revert** - rollback changes for selected files with confirmation

### 🔍 File Comparison
- **🔧 External Diff Tools** - support for Meld, VS Code, FileMerge
- **⚡ Quick Access** - double tap to open folder with file
- **🤚 Smart Gestures** - long press to view changes
- **🎯 Built-in Diff** - fallback change viewing

### 🎨 Interface & UX
- **🔗 Interactive Links** - clickable paths to files and folders
- **📱 Compact List** - optimized file display
- **🌗 Dark/Light Theme** - automatic system adaptation
- **⚡ Hotkeys** - quick actions for productivity
- **💾 Window State Saving** - app remembers window size and position
- **🔄 Auto-save** - window state saved automatically on changes

### 🌈 Visual Indicators
- **🔵 Blue** - modified files (M)
- **🟢 Green** - added files (A)
- **🔴 Red** - deleted files (D)
- **🔘 Grey** - untracked files (?)
- **🟠 Orange** - missing files (!)
- **🟣 Purple** - conflicted files (C)
- **🔷 Teal** - replaced files (R)
- **🟤 Brown** - ignored files (I)
- **🔷 Indigo** - external files (X)
- **🟡 Amber** - obstructed files (~)

### 🌈 File Color Identification
Each file in the list has:
- **Colored status indicator** - circle with status letter
- **Colored file name** - text colored by status
- **Hover tooltip** - hover for status description
- **Legend** - info button shows detailed scheme

## 🚀 Quick Start

### Installation

#### macOS
```bash
brew install --cask vibesvn
```

#### Windows
Download from [Releases](https://github.com/rvgroup/vibesvn/releases)

#### Linux
```bash
sudo snap install vibesvn
```

### Requirements
- **SVN client** (command line tools)
- **macOS**, **Windows** or **Linux**

## 📖 Usage

### 1. Repository Management
- Add SVN repository via "Add Repository" button
- Enter repository URL and credentials
- Repository will automatically detect current revision

### 2. Commit Changes
- Select files for commit using checkboxes or interactive legend
- Write commit message or use template
- Click "Commit"

### 3. File Revert
- **Select files** to revert (modified M, missing !, replaced R)
- **Click button** "Revert" which appears automatically
- **Confirm action** in dialog with file list
- **Files revert** to last committed version
- **List updates** automatically after operation

⚠️ **Warning:** Revert removes all unsaved changes in selected files!

### 4. View Changes
- **Double tap** on file - open folder and select file
- **Long press** on modified file - open diff tool
- **Click on path** - quick navigation to file/folder

## 🔧 Supported Diff Tools

### Meld (recommended)
```bash
brew install meld
```

### VS Code
```bash
code --install-extension ms-vscode.diff
```

### FileMerge (macOS)
Built-in macOS tool

## ⚙️ Advanced Settings

### Diff Tool Configuration
- **External diff tool** - selection from preset tools or manual input
- **Default paths** - default cloning folder
- **Ignored files** - patterns to exclude from commits
- **Proxy server** - corporate network support
- **Commit templates** - custom message templates

### Settings Persistence
All settings are automatically saved and restored on next launch.

### 🔄 Gestures and Hotkeys

#### File Management
- **👆 Single tap** - select/deselect file
- **👆👆 Double tap** - open folder with file
- **🤚 Long press** - open diff tool (for modified files)
- **🔄 File Revert** - select M/!/R files and click "Revert"

#### Navigation
- **Click repository path** - open folder
- **Click URL** - open in browser
- **Click file path** - show file in Finder

### 🖥️ Window Management
- **💾 Auto-save** - window position and size saved on changes
- **🔄 Restore on launch** - window opens at same place and size
- **⚡ Optimized saving** - state saved with delay for performance
- **🚫 Ignore maximization** - size not saved when window is maximized

## 🛠️ Development

### Project Structure
```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
│   ├── repository.dart       # SVN repository model
│   ├── svn_file.dart         # SVN file model
│   └── user_settings.dart    # User settings model
├── services/                 # Business logic
│   ├── svn_service.dart      # SVN operations
│   ├── storage_service.dart  # Local storage
│   ├── theme_service.dart    # Theme management
│   ├── window_service.dart   # Window management
│   └── locale_service.dart   # Internationalization
├── screens/                  # UI screens
│   ├── main_screen.dart      # Main repository list
│   ├── commit_screen.dart    # Commit interface
│   └── settings_screen.dart  # Settings interface
├── widgets/                  # Reusable components
│   └── clickable_text.dart   # Interactive text widget
└── helpers/                  # Utilities
    ├── error_helper.dart     # Error handling
    └── link_helper.dart      # Link utilities
```

### Dependencies
- **Flutter** - UI framework
- **window_manager** - window control
- **shared_preferences** - local storage
- **process_run** - SVN command execution
- **url_launcher** - link opening
- **glob** - pattern matching

### Building
```bash
flutter build macos
flutter build windows
flutter build linux
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter** - amazing UI framework
- **SVN** - version control system
- **Meld** - excellent diff tool
- **VS Code** - great editor

## 📞 Support

- 📧 Email: support@vibesvn.com
- 🐛 Issues: [GitHub Issues](https://github.com/rvgroup/vibesvn/issues)
- 💬 Discord: [VibeSVN Community](https://discord.gg/vibesvn)

---

Made with ❤️ by [RV Group](https://rvgroup.dev)
