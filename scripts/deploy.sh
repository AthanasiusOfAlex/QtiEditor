#!/bin/bash
# QTI Editor - Deployment Script
# Builds release version and optionally creates DMG

set -e  # Exit on error

# Configuration
APP_NAME="QtiEditor"
SCHEME="QtiEditor"
PROJECT="QtiEditor.xcodeproj"
BUILD_DIR="./build"
RELEASE_DIR="${BUILD_DIR}/Build/Products/Release"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_step() {
    echo -e "${BLUE}==>${NC} ${1}"
}

print_success() {
    echo -e "${GREEN}✓${NC} ${1}"
}

print_error() {
    echo -e "${RED}✗${NC} ${1}"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} ${1}"
}

# Parse arguments
CREATE_DMG=false
CLEAN=false
ARCHIVE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dmg)
            CREATE_DMG=true
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --archive)
            ARCHIVE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --clean      Clean build directory before building"
            echo "  --archive    Create Xcode archive instead of direct build"
            echo "  --dmg        Create DMG installer after building"
            echo "  --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Simple release build"
            echo "  $0 --clean --dmg      # Clean build + create DMG"
            echo "  $0 --archive --dmg    # Archive + export + create DMG"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

# Print header
echo ""
echo "╔════════════════════════════════════════╗"
echo "║   QTI Editor - Deployment Script      ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode command line tools not found"
    print_warning "Please install Xcode and run: xcode-select --install"
    exit 1
fi

# Get version info
if [ -f "${PROJECT}/project.pbxproj" ]; then
    VERSION=$(grep -m1 'MARKETING_VERSION' "${PROJECT}/project.pbxproj" | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
    BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION' "${PROJECT}/project.pbxproj" | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
    print_step "Building ${APP_NAME} v${VERSION} (${BUILD})"
else
    print_warning "Could not read version info"
    VERSION="1.0"
    BUILD="1"
fi

# Clean if requested
if [ "$CLEAN" = true ]; then
    print_step "Cleaning build directory..."
    rm -rf "${BUILD_DIR}"
    print_success "Build directory cleaned"
fi

# Build or Archive
if [ "$ARCHIVE" = true ]; then
    print_step "Creating archive..."
    xcodebuild archive \
        -project "${PROJECT}" \
        -scheme "${SCHEME}" \
        -configuration Release \
        -archivePath "${ARCHIVE_PATH}" \
        | grep -E '^(Build|Archive)' || true

    print_success "Archive created at: ${ARCHIVE_PATH}"

    print_step "Exporting app from archive..."
    # Note: This requires exportOptions.plist - create it if needed
    # For now, just note the archive location
    print_warning "To export: Open Xcode Organizer and select the archive"
    APP_PATH="${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app"
else
    print_step "Building release version..."
    xcodebuild \
        -project "${PROJECT}" \
        -scheme "${SCHEME}" \
        -configuration Release \
        -derivedDataPath "${BUILD_DIR}" \
        | grep -E '^(Build|Compile|Link|CodeSign)' || true

    print_success "Build completed"
    APP_PATH="${RELEASE_DIR}/${APP_NAME}.app"
fi

# Verify app bundle exists
if [ ! -d "${APP_PATH}" ]; then
    print_error "App bundle not found at: ${APP_PATH}"
    exit 1
fi

# Check code signature
print_step "Verifying code signature..."
if codesign -vvv --deep --strict "${APP_PATH}" &> /dev/null; then
    print_success "Code signature valid"
else
    print_warning "Code signature verification failed (may be okay for development)"
fi

# Get app info
APP_SIZE=$(du -sh "${APP_PATH}" | cut -f1)
print_success "App size: ${APP_SIZE}"

# Create DMG if requested
if [ "$CREATE_DMG" = true ]; then
    DMG_NAME="${APP_NAME}-${VERSION}.dmg"
    TEMP_DMG_DIR="${BUILD_DIR}/dmg-staging"

    print_step "Creating DMG installer..."

    # Create staging directory
    rm -rf "${TEMP_DMG_DIR}"
    mkdir -p "${TEMP_DMG_DIR}"

    # Copy app to staging
    cp -R "${APP_PATH}" "${TEMP_DMG_DIR}/"

    # Remove old DMG if exists
    [ -f "${DMG_NAME}" ] && rm "${DMG_NAME}"

    # Check if create-dmg is available
    if command -v create-dmg &> /dev/null; then
        print_step "Using create-dmg for prettier installer..."
        create-dmg \
            --volname "${APP_NAME} ${VERSION}" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon "${APP_NAME}.app" 175 190 \
            --hide-extension "${APP_NAME}.app" \
            --app-drop-link 425 190 \
            "${DMG_NAME}" \
            "${TEMP_DMG_DIR}" 2>&1 | grep -v "^hdiutil" || true
    else
        # Fallback to hdiutil
        print_step "Using hdiutil (install 'create-dmg' for prettier DMG)..."
        hdiutil create \
            -volname "${APP_NAME} ${VERSION}" \
            -srcfolder "${TEMP_DMG_DIR}" \
            -ov \
            -format UDZO \
            "${DMG_NAME}" > /dev/null 2>&1
    fi

    # Cleanup
    rm -rf "${TEMP_DMG_DIR}"

    DMG_SIZE=$(du -sh "${DMG_NAME}" | cut -f1)
    print_success "DMG created: ${DMG_NAME} (${DMG_SIZE})"
fi

# Print summary
echo ""
echo "╔════════════════════════════════════════╗"
echo "║          Build Summary                 ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "  App:      ${APP_NAME} v${VERSION} (${BUILD})"
echo "  Location: ${APP_PATH}"
echo "  Size:     ${APP_SIZE}"
if [ "$CREATE_DMG" = true ]; then
    echo "  DMG:      ${DMG_NAME} (${DMG_SIZE})"
fi
echo ""

# Next steps
print_success "Build complete!"
echo ""
echo "Next steps:"
echo "  • Test the app:  open \"${APP_PATH}\""
echo "  • Copy to /Applications for installation"
if [ "$CREATE_DMG" = true ]; then
    echo "  • Share the DMG: ${DMG_NAME}"
else
    echo "  • Create DMG:    $0 --dmg"
fi
echo ""
