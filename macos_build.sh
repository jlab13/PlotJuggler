#!/bin/bash
# Build script for PlotJuggler native macOS application bundle

set -e

BUILD_DIR="build"
INSTALL_DIR="$BUILD_DIR/install"

echo "==> Building PlotJuggler as native macOS application..."

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake
echo "==> Configuring with CMake..."
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PWD/install" ..

# Build
echo "==> Building..."
make -j$(sysctl -n hw.ncpu)

# Install
echo "==> Installing to $INSTALL_DIR..."
make install

# Copy PlotCyphal libraries if they exist
if [ -n "${PLOT_CYPHAL_DIR:-}" ]; then
    PLOT_CYPHAL_BUILD_DIR="$PLOT_CYPHAL_DIR/build"
    if [ -d "$PLOT_CYPHAL_BUILD_DIR" ] && ls "$PLOT_CYPHAL_BUILD_DIR"/libPlotJugglerCyphal* 1> /dev/null 2>&1; then
        echo "==> Copying PlotCyphal libraries from PLOT_CYPHAL_DIR..."
        cp "$PLOT_CYPHAL_BUILD_DIR"/lib* install/plotjuggler.app/Contents/MacOS
    else
        echo "Warning: PlotCyphal build directory not found or no libraries present in PLOT_CYPHAL_DIR."
    fi
fi

# Deploy Qt frameworks
echo "==> Deploying Qt frameworks with macdeployqt..."
QT5_PATH=$(brew --prefix qt@5)
if [ -f "$QT5_PATH/bin/macdeployqt" ]; then
    "$QT5_PATH/bin/macdeployqt" install/plotjuggler.app -verbose=1
else
    echo "Warning: macdeployqt not found. Install Qt5 via Homebrew: brew install qt@5"
fi


echo ""
echo "==> Build complete!"
echo "==> PlotJuggler.app is located at: $INSTALL_DIR/plotjuggler.app"
echo "==> To run: open $INSTALL_DIR/plotjuggler.app"
echo ""
echo "Bundle size:"
du -sh install/plotjuggler.app
echo ""
echo "To sign app, run: ./macos_sign.sh"
echo ""