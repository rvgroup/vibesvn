# 🎉 VibeSVN v1.2.0 - Complete SVN History Management

> Transform VibeSVN from a basic commit tool into a comprehensive SVN solution with professional-grade features

## ✨ Major New Features

### 📊 ShowLog Screen - Complete Repository History
- **Full commit history** - Browse all commits in your repository
- **Smart filtering** - Search by message, file paths, and date ranges
- **Advanced sorting** - Sort by revision, author, date, or message
- **Date format** - European DD.MM.YYYY format for better usability
- **File viewing** - View file contents from any revision
- **Revision comparison** - Diff between any two revisions
- **Blame support** - Line-by-line authorship analysis

### 🎨 External File Viewer Support
- **VS Code** - Professional code editing with syntax highlighting
- **Sublime Text** - Fast and lightweight text editing
- **TextMate** - macOS native text editor
- **Vim** - Powerful command-line editor
- **Nano** - Simple terminal editor
- **Smart integration** - Automatic temporary file creation and cleanup

### 📋 Enhanced Context Menus
- **Cursor positioning** - Menu appears exactly where you tap
- **Professional UX** - Consistent with modern applications
- **Quick actions** - View file, view diff, blame, copy path
- **Visual feedback** - Clear icons and intuitive layout

## 🔧 Technical Improvements

### Enhanced Diff Capabilities
- **Repository URL support** - Compare revisions using SVN URLs
- **External tool integration** - Meld, VS Code, FileMerge support
- **Temporary file management** - Safe file handling with auto-cleanup
- **Error handling** - Better error messages and recovery

### File Management
- **Path handling fixes** - Correct relative/absolute path resolution
- **SVN command optimization** - More reliable SVN operations
- **External tool launching** - Improved process management

### Localization & UX
- **Sorted dictionaries** - Alphabetical key ordering (122 keys)
- **European date format** - DD.MM.YYYY throughout the application
- **Enhanced translations** - Complete Russian and English support

## 🐛 Bug Fixes

### Date & Filter Issues
- Fixed date filter parsing for DD.MM.YYYY format
- Improved date range validation
- Better error handling for invalid dates

### File Path Issues
- Fixed relative path handling in SVN commands
- Corrected absolute path resolution
- Improved file existence checking

### Diff & Blame Issues
- Fixed diff comparison for different revisions
- Improved blame output formatting
- Better error handling for external tool failures

## 📦 Installation & Setup

### Requirements
- **Flutter 3.10.8+**
- **macOS 10.14+**
- **SVN client** (command-line)

### External Tools Setup
1. Open **Settings → Advanced Settings**
2. Configure **External diff tool** (Meld recommended):
   ```bash
   brew install meld
   # Path: /opt/homebrew/bin/meld
   ```
3. Configure **External file viewer** (VS Code recommended):
   ```bash
   # Path: /Applications/Visual Studio Code.app/Contents/Resources/app/bin/code
   ```

## 🚀 New Workflows

### ShowLog Workflow
1. Click **ShowLog** on repository card
2. Use filters to find specific commits
3. **Long press** on file for context menu
4. Choose **View file** or **View diff**
5. External tools open automatically if configured

### Enhanced File Management
1. **Long press** on any file in commit screen
2. Context menu appears at cursor position
3. **View file** - Opens in external editor
4. **View diff** - Opens in external diff tool
5. **Blame** - Opens blame output in external editor

## 📊 Statistics

### Development Metrics
- **12 files changed**
- **1,685 lines added**
- **48 lines removed**
- **2 new screens** (ShowLog, enhanced settings)
- **1 new model** (SvnCommit)

### Application Size
- **macOS build**: 44MB (optimized)
- **Release archive**: 52.6MB
- **Memory usage**: Improved with better file handling

## 🔄 Migration from v1.1.0

### Automatic Updates
- All existing settings preserved
- Repository configurations unchanged
- External tool settings added (optional)

### New Features Access
- **ShowLog button** appears on repository cards
- **Enhanced context menus** in file lists
- **Advanced settings** expanded with file viewer options

## 🎯 Use Cases

### For Developers
- **Code review** - Browse commit history and analyze changes
- **Bug investigation** - Use blame to find who changed specific lines
- **Feature development** - Track evolution of code over time

### For Teams
- **Collaboration** - Share blame information for code ownership
- **Code quality** - Review changes across multiple revisions
- **Documentation** - Generate change reports from commit history

### For DevOps
- **Release management** - Track changes between releases
- **Compliance** - Audit trail of all repository changes
- **Automation** - Scriptable access to SVN history

## 🔮 Future Enhancements

### Planned for v1.3.0
- **Windows and Linux builds** - Cross-platform support
- **Advanced search** - Regular expressions in filters
- **Export functionality** - Export commit history to various formats
- **Integration hooks** - Git integration and CI/CD pipelines

## 🤝 Contributing

We welcome contributions! Please see our [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup
```bash
git clone https://github.com/yourusername/vibesvn.git
cd vibesvn
flutter pub get
flutter run
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter team** - Amazing cross-platform framework
- **SVN community** - Version control system that powers this tool
- **External tool developers** - Meld, VS Code, Sublime Text, TextMate
- **Beta testers** - Valuable feedback and bug reports

---

**Download:** [vibesvn-v1.2.0-macos.zip](https://github.com/yourusername/vibesvn/releases/download/v1.2.0/vibesvn-v1.2.0-macos.zip)

**Size:** 52.6MB | **Platform:** macOS | **Version:** 1.2.0

---

🎊 **Thank you for using VibeSVN!** This release represents a major milestone in our journey to create the perfect SVN client for modern development workflows.
