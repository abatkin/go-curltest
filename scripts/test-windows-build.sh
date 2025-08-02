#!/bin/bash
set -euo pipefail

# Test script to validate Windows cross-compilation
# This script tests that the Windows executable works as expected

echo "=== Testing Windows Cross-compilation ==="

if [ ! -f "curltest.exe" ]; then
    echo "Error: curltest.exe not found. Run cross-compilation first."
    exit 1
fi

echo "Windows executable found:"
ls -la curltest.exe

echo "File type:"
file curltest.exe

echo "Checking executable format..."
if file curltest.exe | grep -q "PE32+ executable"; then
    echo "✓ Correct PE32+ executable format"
else
    echo "✗ Incorrect executable format"
    exit 1
fi

if file curltest.exe | grep -q "x86-64"; then
    echo "✓ Correct x86-64 architecture"
else
    echo "✗ Incorrect architecture"
    exit 1
fi

if file curltest.exe | grep -q "MS Windows"; then
    echo "✓ Correct Windows target"
else
    echo "✗ Incorrect target platform"
    exit 1
fi

echo "Checking for dynamic dependencies..."
if command -v objdump >/dev/null 2>&1; then
    echo "DLL dependencies:"
    x86_64-w64-mingw32-objdump -p curltest.exe | grep "DLL Name" || echo "No DLL dependencies found (static build)"
fi

echo "Executable size:"
wc -c curltest.exe

echo ""
echo "✓ Cross-compilation test passed!"
echo "The executable appears to be a valid Windows x86-64 binary."
echo ""
echo "To fully test functionality, copy curltest.exe to a Windows machine and run:"
echo "  curltest.exe --version"
echo "  curltest.exe https://httpbin.org/get"