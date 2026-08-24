# Satisfactory GRUB themes

## Installation

This is the installation script's help menu.

> [!IMPORTANT]
> This script has to be run with root privileges as it modifies GRUB configuration

```
Usage: sudo ./install.sh [options]

Options:
    -h                                      Shows this help menu
    -t [og|train|update1|update3|1.2]       Specifies a theme variant                                       (default=og)
    -r [1080p|1440p|4k]                     Specifies a screen resolution                                   (default=1080p)
    -a [16:9|16:10|21:9]                    Specifies the aspect ratio for the current resolution           (default=16:9)
    -d                                      Deletes the current installed theme variant
    -p <path>                               Specifies the GRUB themes path for the selected theme           (default=/boot/grub2/themes or /boot/grub/themes)
```

### Examples

```sh
# Installs the 'og' theme for a 1080p display device
sudo ./install.sh

# Installs the 'train' theme for a 1440p display device
sudo ./install.sh -t train -r 1440p

# Installs the 'og' theme for an ultrawide (21:9) 4k display device
sudo ./install.sh -r 4k -a 21:9

# Installs the '1.2' theme for a 16:10 1080p display device
sudo ./install.sh -t 1.2 -a 16:10

# Installs the theme in another path from the default
sudo ./install.sh -p "<some other path>"

# Uninstalls the current theme variant
sudo ./install.sh -d
```

## Supported resolutions

|       | 16:9 (widescren) | 16:10 (widescren) | 21:9 (ultrawide) |
|-------|------------------|-------------------|------------------|
| 1080p |         ✅       |         ✅        |         ✅       |
| 1440p |         ✅       |         ✅        |         ✅       |
| 4k    |         ✅       |         ✅        |         ✅       |

Those are the supported resolutions for all themes. If your device has another resolution from the ones supported, please open an issue or a pull request so that it can be supported.

## Available themes

Themes are available in all resolutions.

### OG

![OG theme](https://github.com/Spokloo/satisfactory-grub-themes/blob/main/previews/satisfactory-og-theme.png?raw=true "OG theme")

### Train

![Train theme](https://github.com/Spokloo/satisfactory-grub-themes/blob/main/previews/satisfactory-train-theme.png?raw=true "Train theme")

### Update 1

![Update 1 theme](https://github.com/Spokloo/satisfactory-grub-themes/blob/main/previews/satisfactory-update1-theme.png?raw=true "Update 1 theme")

### Update 3

![Update 3 theme](https://github.com/Spokloo/satisfactory-grub-themes/blob/main/previews/satisfactory-update3-theme.png?raw=true "Update 3 theme")

### 1.2

![1.2 theme](https://github.com/Spokloo/satisfactory-grub-themes/blob/main/previews/satisfactory-1.2-theme.png?raw=true "1.2 theme")
