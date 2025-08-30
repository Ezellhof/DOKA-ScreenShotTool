# 🚧 OP-Tool: ScreenAssembly

## ✨ Features

- 🎉 **No Windows Admin User needed** - Just execute as plain old **USER**
- 💎 **Windows Context Menu Integration** (Optional) - Use the Script via Right Click on Folder **[See Video](#windows-context-menu)**
- 🔩 **Parallel Execution** - Make Countless Montages at the same time in Seconds **[See Video](#parallel-execution)**
- ⚙️ **No Install** - Auto Downloads precompiled x64 Windows-Binary
- 📸 **Unlimited Folders** - Process any number of PNG files in any Number of Folders
- 🤖 **Smart Auto-Detection** - Automatically analyzes your images
- 🎨 **Intelligent Theming** - Auto Dark/Light mode Background based on average brightness
- 📐 **Optimal Layouts** - Auto Portrait/Widescreen based on quantity & dimensions
- ⚡ **Perfect Grids** - Calculates best column/row arrangements
- 🎯 **Clean Output** - High-Quality Screenshot-Montages with colored Borders and high Resolution **[See Video](#clean-output--zoom)**
- 🔧 **Zero Setup** - Automatically downloads the latest prebuilt Binary **[ImageMagick](https://github.com/ImageMagick/ImageMagick)**

## 🎯 Auto Mode Intelligence

- **🔍 Brightness Analysis** - Scans average pixel brightness
- **📐 Dimension Detection** - Analyzes aspect ratios and image sizes
- **📊 Smart Decisions** - Analysis-based decisions for which Grid to use **(MATH PART DEFENITLY NOT CODED BY AI)**

## 🔞 Disclaimer 
- I am **not responsible** for **deleted Screenshots, still open Helpdesk-Tickets, thermonuclear war 💣**, or you getting **fired** because your alarm app failed. **Please read the [📋Script]() before Execution!**

-----

# 🚀 Quick Start

## 💎 With Windows Contex Menu Integration:

- Select as many Folders as you want => Rightclick => Click **OP-ScreenMontage** **[See Video](#windows-context-menu-integration)**

## 🛸 Without Contex Menu Integration:
```powershell
# Rename OP-ScreenAssembly.txt => OP-ScreenAssembly.ps1
mv OP-ScreenAssembly.txt OP-ScreenAssembly.ps1
# Yes you can also do it in the GUI :)

# Automatic mode (recommended) also checks if Tool is Steup and if not will execute Setup
.\OP-ScreenAssembly_v1.0.ps1 -a .\screenshot-folder\

# Setup ImageMagick
.\OP-ScreenAssembly_v1.0.ps1 -setup
```

### 📋 Flags / Command Options

| Option | Description | Example |
|--------|-------------|---------|
| `-setup` | ⚙️ **Setup** - Install/Update ImageMagick & ContextMenuAddon | `-setup` |
| `-a` | 🤖 **Auto Mode** - Smart detection **(Recommended)** | `-a .\screenshot-folder\` |
| `-t` | 🧪 **Test Mode** - Creates all 4 combinations | `-t .\screenshot-folder\` |
| `-p` | 📱 **Portrait** - Vertical layout | `-p -d .\screenshot-folder\` |
| `-w` | 🖥️ **Widescreen** - Horizontal layout | `-w -l .\screenshot-folder\` |
| `-d` | 🌙 **Dark Theme** - Dark background & pink borders | `-p -d .\screenshot-folder\` |
| `-l` | ☀️ **Light Theme** - Light background & purple borders | `-w -l .\screenshot-folder\` |

## 📁 Output Files

- `Portrait_Dark_ScreenshotFolderName_Auto.png`
- `Portrait_Light_ScreenshotFolderName.png` 
- `Widescreen_Dark_ScreenshotFolderName.png`
- `Widescreen_Light_ScreenshotFolderName.png`

-----

# 💡Guides & Help

## 💎 Windows Context Menu:

[![Thumbnail](assets\video\thumbnails\context_thumb.jpg)](assets/video/doc_context.mp4)

- Click **Install_ContextMenu_Screenmontage.reg**
- Answer the Password promot for your **Local Windows User**

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

- (WIP LONG TERM) Make a [DISCOSII]() **Wizard/Masks/Buttons/Dialog-Screenshot-Database** (Maybe Automation or Intern)
    - Make ScreenAssembly with OCR and PixelCompare and maybe even AI comapre screenshots to DB and Label them
    - Idea: Is there not some ugly new windows feature which screenshots your desktop 24/7 => Instant DB
- (WIP) Play around with ImageMagick-OCR if its good enoght use it even without compare-DB
- Add functionalltiy to eat any File Format (.jpg, .jpeg, .bmp, .more)
- Add Output Argument/ContextMenuDialog like (LowSize, BigBoySize, .FileFormats, .Filename)
- Add Custom ColorPicker (No clue if that is even possible in a Terminal) also useless Feature tbh.
- Make a "/usr/bin/bash" Version that is not full of weird AI-Generated-Code **(And MacOS people)**

-----

- *Made with ❤️ by ezellhof
- Coding is done 90% by AI so dont tell me any bugs post them in your own ChatGpt and mail me the fixes!*
- *Inspired by the holy Helpdesk 🖥️*

-----

Credits:

[![Name](https://img.shields.io/badge/Name-Aigner%20Johannes-blue)](https://teams.microsoft.com/l/chat/19:0601fe92-dd52-4d8f-9194-6c302359bd36_b2b0f7d4-7c2e-4bba-a0f9-0721a1ec4acc@unq.gbl.spaces/conversations?context=%7B%22contextType%22%3A%22chat%22%7D)