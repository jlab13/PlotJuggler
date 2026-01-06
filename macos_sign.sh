#!/bin/bash

set -e
echo "==> Signing PlotJuggler macOS application..."

# Code sign the application with Developer ID
cd build
if [ -n "${SIGN_IDENTITY:-}" ]; then
  echo "==> Code signing with: $SIGN_IDENTITY"
  
  # Функція для рекурсивного підпису
  sign_item() {
    local item="$1"
    
    # Пропускаємо, якщо файл не існує
    [ -e "$item" ] || return 0
    
    # Якщо це тека, рекурсивно обробляємо її вміст
    if [ -d "$item" ]; then
      # Перевіряємо, чи це bundle (.app, .framework, .bundle, .plugin)
      if [[ "$item" =~ \.(app|framework|bundle|plugin|dylib)$ ]] || [ -f "$item/Contents/Info.plist" ]; then
        echo "Signing bundle: $(basename "$item")"
        codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$item" 2>/dev/null || true
      else
        # Рекурсивно обробляємо вміст теки
        for subitem in "$item"/*; do
          sign_item "$subitem"
        done
      fi
    # Якщо це файл, перевіряємо чи потрібно його підписувати
    elif [ -f "$item" ]; then
      # Підписуємо dylib, so, та виконувані файли
      if [[ "$item" =~ \.(dylib|so)$ ]] || [ -x "$item" ]; then
        echo "Signing: $(basename "$item")"
        codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$item" 2>/dev/null || true
      fi
    fi
  }
  
  # Підписуємо frameworks
  if [ -d "install/plotjuggler.app/Contents/Frameworks" ]; then
    for item in install/plotjuggler.app/Contents/Frameworks/*; do
      sign_item "$item"
    done
  fi
  
  # Підписуємо plugins
  if [ -d "install/plotjuggler.app/Contents/PlugIns" ]; then
    for item in install/plotjuggler.app/Contents/PlugIns/*; do
      sign_item "$item"
    done
  fi
  
  # Підписуємо виконувані файли в MacOS
  if [ -d "install/plotjuggler.app/Contents/MacOS" ]; then
    for item in install/plotjuggler.app/Contents/MacOS/*; do
      sign_item "$item"
    done
  fi
  
  # Підписуємо сам app bundle
  echo "Signing main bundle: plotjuggler.app"
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" install/plotjuggler.app
  echo "==> Code signing completed"
else
  echo "Warning: SIGN_IDENTITY not set, using ad-hoc signature"
  codesign --deep --force --sign - install/plotjuggler.app
fi

# Створення zip-архіву для нотаризації
# echo "==> Creating zip archive for notarization..."
# cd install
# ditto -c -k --keepParent plotjuggler.app plotjuggler.zip
# cd ..
# 
# # Відправка на нотаризацію
# echo "==> Submitting to Apple notarization service..."
# xcrun notarytool submit install/plotjuggler.zip --wait --team-id "$TEAM_ID" --apple-id "$APPLE_ID" --keychain-profile "notary-profile"
# 
# 
# # Прикріплення нотаризації до додатку
# echo "==> Stapling notarization ticket..."
# xcrun stapler staple install/plotjuggler.app
# 
# # Очищення zip-архіву
# rm -f install/plotjuggler.zip
# 
# echo "==> Done! Application signed and notarized."


echo "To create a DMG for distribution, you can use:"
echo "  brew install create-dmg"
echo "  create-dmg --volname 'PlotJuggler' --window-pos 200 120 --window-size 800 400 \\"
echo "    --icon-size 100 --icon 'PlotJuggler.app' 200 190 --hide-extension 'PlotJuggler.app' \\"
echo "    --app-drop-link 600 185 'PlotJuggler.dmg' install/plotjuggler.app"
