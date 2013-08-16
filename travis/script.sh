#!/bin/sh
set -e

xctool -workspace GCDObjects.xcworkspace -scheme GCDObjects -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO build-tests run-tests

