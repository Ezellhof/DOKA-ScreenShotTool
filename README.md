# 🚧 OP-Tool: ScreenAssembly

```
╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║ ...................................................................... ║
║ ...................................................................... ║
║ .....@@@@@@@@@@...............@@..............@@...................... ║
║ ....@@..@@.....@.............@@@.............@@@...................... ║
║ ....@@@@@@@@@..@......@@@@@@@@@@..@@@@@@@@@.@@@...@@@@..@@@@@@@@...... ║
║ ....@@@@@@@@@@.@....@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..@@@@@@@@@@@@.... ║
║ ....@@.@@@@@@@@@...@@@......@@@@@@@.....@@@@@@@@@@...@@@......@@@..... ║
║ ....@@@@@@@@@@@@...@@@@@@@@@@@@@@@@@@@@@@@@@@@.@@@@@.@@@@@@@@.@@@..... ║
║ .....@@@@@@@@@@@....@@@@@@@@....@@@@@@@@...@@@...@@@@.@@@@@...@@...... ║
║ ...................................................................... ║
║ ...................................................................... ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝
```

## ✨ Features

- 🎉 **No Windows Admin User needed** - Just execute as plain old **USER**
- 💎 **Automated Setup & Installation** - Complete one-command setup with optional context menu integration
- 💎 **Windows Context Menu Integration** (Optional) - Use the Script via Right Click on Folder **[See Video](#windows-context-menu)**
- 🔩 **Parallel Execution** - Make Countless Montages at the same time in Seconds **[See Video](#parallel-execution)**
- ⚙️ **Zero-Config Installation** - Auto Downloads & installs portable ImageMagick to LocalAppData
- 📸 **Unlimited Folders** - Process any number of PNG files in any Number of Folders
- 🤖 **Smart Auto-Detection** - Automatically analyzes your images
- 🎨 **Intelligent Theming** - Auto Dark/Light mode Background based on average brightness
- 📐 **Optimal Layouts** - Auto Portrait/Widescreen based on quantity & dimensions
- ⚡ **Perfect Grids** - Calculates best column/row arrangements
- 🎯 **Clean Output** - High-Quality Screenshot-Montages with colored Borders and high Resolution **[See Video](#clean-output--zoom)**
- �️ **Portable & Self-Contained** - No system-wide installs, everything in user space
- 🔧 **Smart Asset Management** - Auto-downloads latest ImageMagick with version detection
- 📋 **Dynamic Registry Files** - Generates personalized Windows context menu files during setup

## 🎯 Auto Mode Intelligence

- **🔍 Brightness Analysis** - Scans average pixel brightness
- **📐 Dimension Detection** - Analyzes aspect ratios and image sizes
- **📊 Smart Decisions** - Analysis-based decisions for which Grid to use **(MATH PART DEFENITLY NOT CODED BY AI)**

## 🔞 Disclaimer 
- I am **not responsible** for **deleted Screenshots, still open Helpdesk-Tickets, thermonuclear war 💣**, or you getting **fired** because your alarm app failed. **Please read the [📋Script]() before Execution!**

-----

# 🚀 Quick Start

## 🎯 One-Command Setup (Recommended)

```powershell
# Complete setup with optional context menu integration
.\OP-min_ScreenAssembly.ps1 -setup

# The setup will:
# ✅ Download & install portable ImageMagick
# ✅ Create scmontage command alias  
# ✅ Generate personalized registry files
# ✅ Ask if you want Windows context menu integration (Y/n)
```

## 💎 With Windows Context Menu Integration:

- Select as many Folders as you want => Rightclick => Click **OP-ScreenAssembly (Auto)** **[See Video](#windows-context-menu-integration)**
- Or use the generated `Install_Context_Menu.reg` file for manual installation

## 🛸 Without Context Menu Integration:
```powershell
# After setup, use from anywhere:
scmontage -a .\screenshot-folder\

# Or direct script execution:
.\OP-min_ScreenAssembly.ps1 -a .\screenshot-folder\

# Reinstall/refresh tool assets:
.\OP-min_ScreenAssembly.ps1 -reinstall
```

### 📋 Flags / Command Options

| Option | Description | Example |
|--------|-------------|---------|
| `-setup` | ⚙️ **Complete Setup** - Install ImageMagick, create registry files, optional context menu | `-setup` |
| `-reinstall` | 🔄 **Refresh Assets** - Update script, shim, and environment without ImageMagick | `-reinstall` |
| `-a` | 🤖 **Auto Mode** - Smart detection **(Recommended)** | `-a .\screenshot-folder\` |
| `-t` | 🧪 **Test Mode** - Creates all 4 combinations | `-t .\screenshot-folder\` |
| `-p` | 📱 **Portrait** - Vertical layout | `-p -d .\screenshot-folder\` |
| `-w` | 🖥️ **Widescreen** - Horizontal layout | `-w -l .\screenshot-folder\` |
| `-d` | 🌙 **Dark Theme** - Dark background & pink borders | `-p -d .\screenshot-folder\` |
| `-l` | ☀️ **Light Theme** - Light background & purple borders | `-w -l .\screenshot-folder\` |

## 🎯 Setup Features

- **🏠 LocalAppData Installation** - No admin rights required, installed to `%LOCALAPPDATA%\OP-ScreenAssembly`
- **🔗 Global Access** - Creates `scmontage` command available from any directory
- **📋 Dynamic Registry Files** - Generates personalized context menu files for your system
- **🎨 ASCII Art Branding** - Beautiful terminal output with DOKA logo and colored borders
- **🔄 Version Management** - Automatic ImageMagick version detection and updates

## 📁 Output Files

- `Portrait_Dark_ScreenshotFolderName_Auto.png`
- `Portrait_Light_ScreenshotFolderName.png` 
- `Widescreen_Dark_ScreenshotFolderName.png`
- `Widescreen_Light_ScreenshotFolderName.png`

## 🔧 Installation Details

After running `-setup`, the following files are created:

**📍 In `%LOCALAPPDATA%\OP-ScreenAssembly\`:**
- `OP-ScreenAssembly.ps1` - Main script
- `scmontage.cmd` - Global command shim
- `Doka.ico` - Context menu icon
- `doka_ascii.txt` - ASCII art for branding
- `Install_Context_Menu.reg` - Context menu installer
- `Uninstall_Context_Menu.reg` - Context menu remover

**📍 In script directory:**
- `Install_Context_Menu.reg` - Copy for easy access
- `Uninstall_Context_Menu.reg` - Copy for easy access

**🌐 Environment:**
- `scmontage` command available globally
- `SCMONTAGE` environment variable set
- User PATH updated with tool directory

-----

# 💡Guides & Help

## 💎 Windows Context Menu:

[![Thumbnail](assets\video\thumbnails\context_thumb.jpg)](assets/video/doc_context.mp4)

**🆕 Automated Installation:**
- Run `.\OP-min_ScreenAssembly.ps1 -setup`
- When prompted "Install Windows Context Menu Integration? (Y/n)", press Enter or type Y
- UAC prompt will appear - click Yes to install

**📋 Manual Installation:**
- Use the generated `Install_Context_Menu.reg` file (created during setup)
- Double-click and accept the registry modification prompt

---

## 🔩 Parallel Execution:

[![Thumbnail](assets\video\thumbnails\parallel_thumb.jpg)](assets/video/doc_parallel.mp4)

- **Process multiple** screenshot folders simultaneously for **maximum efficiency.**

---

## 🎯 Clean Output & Zoom:

[](assets/video/doc_zoom.mp4)
[![Thumbnail](assets\video\thumbnails\zoom_thumb.jpg)](assets/video/doc_zoom.mp4)

- Explore the **High-Quality** output and **Zoom functionality** of the generated montages.

---

# 🧭 Roadmap

- **✅ COMPLETED TODAY**: Complete setup automation with context menu integration
- **✅ COMPLETED TODAY**: Beautiful ASCII art branding with colored borders
- **✅ COMPLETED TODAY**: Template-based registry file generation
- **✅ COMPLETED TODAY**: LocalAppData portable installation
- **✅ COMPLETED TODAY**: Global `scmontage` command with PATH integration

**🔮 Future Plans:**
- (WIP LONG TERM) Make a [DISCOSII]() **Wizard/Masks/Buttons/Dialog-Screenshot-Database** (Maybe Automation or Intern)
    - Make ScreenAssembly with OCR and PixelCompare and maybe even AI compare screenshots to DB and Label them
    - Idea: Is there not some ugly new windows feature which screenshots your desktop 24/7 => Instant DB
- (WIP) Play around with ImageMagick-OCR if its good enough use it even without compare-DB
- Add functionality to eat any File Format (.jpg, .jpeg, .bmp, .more)
- Add Output Argument/ContextMenuDialog like (LowSize, BigBoySize, .FileFormats, .Filename)
- Add Custom ColorPicker (No clue if that is even possible in a Terminal) also useless Feature tbh.
- Make a "/usr/bin/bash" Version that is not full of weird AI-Generated-Code **(And MacOS people)**

-----

**🎨 Made with ❤️ by ezellhof**

```
╔════════════════════════════════════════════════════════════════════════╗
║   Tool successfully optimized with full functionality                  ║
║   Made for Doka by ezellhof                                            ║ 
║   https://github.com/Ezellhof/DOKA-ScreenShotTool                      ║
╠════════════════════════════════════════════════════════════════════════╣
║ ...................................................................... ║
║ ...................................................................... ║
║ .....@@@@@@@@@@...............@@..............@@...................... ║
║ ....@@..@@.....@.............@@@.............@@@...................... ║
║ ....@@@@@@@@@..@......@@@@@@@@@@..@@@@@@@@@.@@@...@@@@..@@@@@@@@...... ║
║ ....@@@@@@@@@@.@....@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..@@@@@@@@@@@@.... ║
║ ....@@.@@@@@@@@@...@@@......@@@@@@@.....@@@@@@@@@@...@@@......@@@..... ║
║ ....@@@@@@@@@@@@...@@@@@@@@@@@@@@@@@@@@@@@@@@@.@@@@@.@@@@@@@@.@@@..... ║
║ .....@@@@@@@@@@@....@@@@@@@@....@@@@@@@@...@@@...@@@@.@@@@@...@@...... ║
║ ...................................................................... ║
║ ...................................................................... ║
╚════════════════════════════════════════════════════════════════════════╝
```

- *Coding is done 90% by AI so don't tell me any bugs post them in your own ChatGPT and mail me the fixes!*
- *Inspired by the holy Helpdesk 🖥️*

-----

Credits:

[![Name](https://img.shields.io/badge/Name-Aigner%20Johannes-blue)](https://teams.microsoft.com/l/chat/19:0601fe92-dd52-4d8f-9194-6c302359bd36_b2b0f7d4-7c2e-4bba-a0f9-0721a1ec4acc@unq.gbl.spaces/conversations?context=%7B%22contextType%22%3A%22chat%22%7D)