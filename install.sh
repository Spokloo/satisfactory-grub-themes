#!/bin/bash

# Exit on error
set -euo pipefail

THEMES_LIST=("og" "train" "update1" "update3" "1.2")
RES_LIST=("1080p" "1440p" "4k")
ASPECT_RATIO_LIST=("16:9" "16:10" "21:9")

DEFAULT_GRUB_PATH=""
if [[ -d "/boot/grub" ]]; then
  DEFAULT_GRUB_PATH="/boot/grub/themes"
fi
if [[ -d "/boot/grub2" ]]; then
  DEFAULT_GRUB_PATH="/boot/grub2/themes"
fi

if [[ -z "$DEFAULT_GRUB_PATH" ]]; then
    echo "GRUB path '/boot/grub' or '/boot/grub2' not found. Aborting installation..." >&2
    exit 1
fi

DEFAULT_GRUB_CFG_PATH="/etc/default/grub"
if [[ ! -f "$DEFAULT_GRUB_CFG_PATH" ]]; then
    echo "Could not find GRUB config file at '$DEFAULT_GRUB_CFG_PATH'. Aborting installation..." >&2
    exit 1
fi

DEFAULT_THEME="${THEMES_LIST[0]}"
DEFAULT_RES="${RES_LIST[0]}"
DEFAULT_RATIO="${ASPECT_RATIO_LIST[0]}"

# Help menu
print_usage() {
    cat << EOF
Usage: sudo $(basename "$0") [options]

Options:
    -h                                      Shows this help menu
    -t [og|train|update1|update3|1.2]       Specifies a theme variant                                       (default=$DEFAULT_THEME)
    -r [1080p|1440p|4k]                     Specifies a screen resolution                                   (default=$DEFAULT_RES)
    -a [16:9|16:10|21:9]                    Specifies the aspect ratio for the current resolution           (default=$DEFAULT_RATIO)
    -d                                      Deletes the current installed theme variant
    -p <path>                               Specifies the GRUB themes path for the selected theme           (default=$DEFAULT_GRUB_PATH)
EOF
}

# Parse options
selected_theme="$DEFAULT_THEME"
selected_res="$DEFAULT_RES"
selected_ratio="$DEFAULT_RATIO"
delete_theme=false
install_path="$DEFAULT_GRUB_PATH/satisfactory"

parse_options() {
    OPTIND=1

    while getopts ":ht:r:a:dp:" opt; do
        case "$opt" in
            h)
                print_usage
                exit 0
                ;;
            t)
                # Theme validation
                valid_theme=0
                for theme in "${THEMES_LIST[@]}"; do
                    if [[ "$OPTARG" == "$theme" ]]; then
                        valid_theme=1
                        break
                    fi
                done

                if [ "$valid_theme" = 1 ]; then
                    selected_theme="$OPTARG"
                else
                    echo "Invalid theme. Expected one of those values: ${THEMES_LIST[*]}" >&2
                    exit 1
                fi
                ;;
            r)
                # Resolution validation
                valid_res=0
                for res in "${RES_LIST[@]}"; do
                    if [[ "$OPTARG" == "$res" ]]; then
                        valid_res=1
                        break
                    fi
                done

                if [ "$valid_res" = 1 ]; then
                    selected_res="$OPTARG"
                else
                    echo "Invalid resolution. Expected one of those values: ${RES_LIST[*]}" >&2
                    exit 1
                fi
                ;;
            a)
                # Aspect ratio validation
                valid_ratio=0
                for ratio in "${ASPECT_RATIO_LIST[@]}"; do
                    if [[ "$OPTARG" == "$ratio" ]]; then
                        valid_ratio=1
                        break
                    fi
                done

                if [ "$valid_ratio" = 1 ]; then
                    selected_ratio="$OPTARG"
                else
                    echo "Invalid aspect ratio. Expected one of those values: ${ASPECT_RATIO_LIST[*]}" >&2
                    exit 1
                fi
                ;;
            d)
                delete_theme=true
                ;;
            p)
                install_path="$OPTARG/satisfactory"
                ;;
            :)
                echo "Missing argument for -$OPTARG" >&2
                print_usage
                exit 1
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                print_usage
                exit 1
                ;;
        esac
    done

    shift $((OPTIND-1))
    return 0
}

# Update GRUB once config has been edited
update_grub_cfg() {
    echo "Updating GRUB config..."

    # Check for each available command
    if command -v update-grub &>/dev/null; then
        update-grub
    elif command -v grub-mkconfig &>/dev/null; then
        local cfg_path="/boot/grub/grub.cfg"

        if [[ ! -f "$cfg_path" && -f "/boot/grub2/grub.cfg" ]]; then
            cfg_path="/boot/grub2/grub.cfg"
        fi

        grub-mkconfig -o "$cfg_path"
    elif command -v grub2-mkconfig &>/dev/null; then
        local cfg_path="/boot/grub2/grub.cfg"

        # Special check for Fedora
        if [[ ! -f "$cfg_path" && -f "/boot/efi/EFI/fedora/grub.cfg" ]]; then
            cfg_path="/boot/efi/EFI/fedora/grub.cfg"
        elif [[ ! -f "$cfg_path" && -f "/boot/grub/grub.cfg" ]]; then
            cfg_path="/boot/grub/grub.cfg"
        fi

        grub2-mkconfig -o "$cfg_path"
    else
        echo "Could not automatically update GRUB configuration. Exiting..." >&2
        exit 1
    fi
}

# Install theme into GRUB
install_theme() {
    local base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P)"

    # Create theme directory
    if [[ -d "$install_path" ]]; then
        rm -rf "$install_path"
    fi
    echo "Creating GRUB theme directory at '$install_path'..."
    mkdir -p "$install_path"

    # Select correct directory based on the selected aspect ratio
    local bg_dir=""
    case "$selected_ratio" in
        16:9)
            bg_dir="bg-16-9"
            ;;
        16:10)
            bg_dir="bg-16-10"
            ;;
        21:9)
            bg_dir="bg-21-9"
            ;;
    esac

    # Copy theme files
    echo "Copying theme '$selected_theme' files into '$install_path'..."

    cp "$base_dir/themes/theme-$selected_res.txt" "$install_path/theme.txt"
    cp "$base_dir/assets/fonts/"*.pf2 "$install_path"
    cp "$base_dir/assets/$selected_res/"*.png "$install_path"
    cp "$base_dir/assets/$selected_res/select/"*.png "$install_path"
    cp "$base_dir/assets/$selected_res/$bg_dir/$selected_theme/background.png" "$install_path"
    cp "$base_dir/assets/$selected_res/$bg_dir/vignette.png" "$install_path"

    # Backing up GRUB config
    if [[ -f "${DEFAULT_GRUB_CFG_PATH}.bak" ]]; then
        echo "GRUB config backup at '${DEFAULT_GRUB_CFG_PATH}.bak' already exists!"
    else
        echo "Creating backup of GRUB config at '${DEFAULT_GRUB_CFG_PATH}.bak'..."
        cp -an "$DEFAULT_GRUB_CFG_PATH" "${DEFAULT_GRUB_CFG_PATH}.bak"
    fi

    # Set theme as default
    echo "Setting theme '$selected_theme' as default..."
    if grep -q "^GRUB_THEME=" "$DEFAULT_GRUB_CFG_PATH"; then
        sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$install_path/theme.txt\"|" "$DEFAULT_GRUB_CFG_PATH"
    else
        echo "GRUB_THEME=\"$install_path/theme.txt\"" >> "$DEFAULT_GRUB_CFG_PATH"
    fi

    # Set GRUB_GFXMODE to the selected screen resolution
    local gfxmode=""
    case "$selected_res" in
        1080p)
            case "$selected_ratio" in
                16:9)
                    gfxmode="1920x1080,auto"
                    ;;
                16:10)
                    gfxmode="1920x1200,1920x1080,auto"
                    ;;
                21:9)
                    gfxmode="2560x1080,1920x1080,auto"
                    ;;
            esac
            ;;
        1440p)
            case "$selected_ratio" in
                16:9)
                    gfxmode="2560x1440,1920x1080,auto"
                    ;;
                16:10)
                    gfxmode="2560x1600,2560x1440,auto"
                    ;;
                21:9)
                    gfxmode="3440x1440,2560x1440,auto"
                    ;;
            esac
            ;;
        4k)
            case "$selected_ratio" in
                16:9)
                    gfxmode="3840x2160,2560x1440,auto"
                    ;;
                16:10)
                    gfxmode="3840x2400,3840x2160,auto"
                    ;;
                21:9)
                    gfxmode="5120x2160,3840x2160,auto"
                    ;;
            esac
            ;;
    esac

    if grep -q "^GRUB_GFXMODE=" "$DEFAULT_GRUB_CFG_PATH"; then
        sed -i "s|^GRUB_GFXMODE=.*|GRUB_GFXMODE=\"$gfxmode\"|" "$DEFAULT_GRUB_CFG_PATH"
    else
        echo "GRUB_GFXMODE=\"$gfxmode\"" >> "$DEFAULT_GRUB_CFG_PATH"
    fi

    # Disabling older settings that would prevent the theme from working correctly
    if grep -q "^GRUB_BACKGROUND=" "$DEFAULT_GRUB_CFG_PATH"; then
        sed -i "s|^GRUB_BACKGROUND=|#GRUB_BACKGROUND=|" "$DEFAULT_GRUB_CFG_PATH"
    fi

    if grep -q "^GRUB_TERMINAL=console" "$DEFAULT_GRUB_CFG_PATH" || grep -q "^GRUB_TERMINAL=\"console\"" "$DEFAULT_GRUB_CFG_PATH"; then
        sed -i "s|^GRUB_TERMINAL=.*|#GRUB_TERMINAL=console|" "$DEFAULT_GRUB_CFG_PATH"
    fi

    if grep -q "^GRUB_TERMINAL_OUTPUT=console" "$DEFAULT_GRUB_CFG_PATH" || grep -q "^GRUB_TERMINAL_OUTPUT=\"console\"" "$DEFAULT_GRUB_CFG_PATH"; then
        sed -i "s|^GRUB_TERMINAL_OUTPUT=.*|#GRUB_TERMINAL_OUTPUT=console|" "$DEFAULT_GRUB_CFG_PATH"
    fi

    # Update GRUB config
    update_grub_cfg

    echo "=============================="
    echo "Satisfactory theme variant '$selected_theme' has successfully been installed!"
    echo "ADA is disappointed that you wasted time and resources on aesthetics..."
    echo "Be efficient."
    return 0
}

# Uninstall theme from GRUB
uninstall_theme() {
    # Delete theme folder
    if [[ -d "$install_path" ]]; then
        echo "Removing theme folder '$install_path'..."
        rm -rf "${install_path:?}"
    fi

    # Restore GRUB config
    if [[ -f "${DEFAULT_GRUB_CFG_PATH}.bak" ]]; then
        echo "Restoring original GRUB config from backup..."
        cp -f "${DEFAULT_GRUB_CFG_PATH}.bak" "$DEFAULT_GRUB_CFG_PATH"
        rm -f "${DEFAULT_GRUB_CFG_PATH}.bak"
    else
        echo "Disabling theme in GRUB config..."
        sed -i "s|^GRUB_THEME=|#GRUB_THEME=|" "$DEFAULT_GRUB_CFG_PATH"
    fi

    # Update GRUB config
    update_grub_cfg

    echo "=============================="
    echo "Satisfactory theme successfully uninstalled!"
    echo "ADA is pleased with your choice to refocus on efficiency."
    echo "Do not forget that FICSIT owns your soul."
    return 0
}

main() {
    # Check root privileges
    if [[ "$EUID" -ne 0 ]]; then
        echo "This script should be run with root privileges." >&2
        exit 1
    fi

    parse_options "$@"

    # Display selected options
    local res_str=""
    case "$selected_res" in
        1080p)
            case "$selected_ratio" in
                16:9)
                    res_str="1920x1080"
                    ;;
                16:10)
                    res_str="1920x1200"
                    ;;
                21:9)
                    res_str="2560x1080"
                    ;;
            esac
            ;;
        1440p)
            case "$selected_ratio" in
                16:9)
                    res_str="2560x1440"
                    ;;
                16:10)
                    res_str="2560x1600"
                    ;;
                21:9)
                    res_str="3440x1440"
                    ;;
            esac
            ;;
        4k)
            case "$selected_ratio" in
                16:9)
                    res_str="3840x2160"
                    ;;
                16:10)
                    res_str="3840x2400"
                    ;;
                21:9)
                    res_str="5120x2160"
                    ;;
            esac
            ;;
    esac

    # Install/delete theme
    echo "=============================="
    if [ "$delete_theme" = true ]; then
        echo "Action: Uninstalling"
        echo "Target path: $install_path"
        echo "=============================="

        uninstall_theme
    else
        echo "Selected theme: $selected_theme"
        echo "Selected resolution: $res_str"
        echo "Selected aspect ratio: $selected_ratio"
        echo "Action: Installing"
        echo "Target path: $install_path"
        echo "=============================="

        install_theme
    fi
}

main "$@"

