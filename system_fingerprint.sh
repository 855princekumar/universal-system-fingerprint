#!/usr/bin/env bash

set -e
set -o pipefail

TS=$(date +"%Y%m%d_%H%M%S")
OUT="system_fingerprint_${TS}.txt"

exec > >(tee "$OUT") 2>&1

echo "=================================================="
echo " SYSTEM FINGERPRINT REPORT"
echo " Generated: $(date)"
echo "=================================================="
echo

######################################
# BASIC SYSTEM
######################################
echo "===== HOST ====="
hostname
echo

echo "===== OS ====="
if command -v lsb_release >/dev/null 2>&1; then
  lsb_release -a
else
  cat /etc/os-release
fi
echo

echo "===== KERNEL ====="
uname -a
echo

######################################
# ARCHITECTURE
######################################
echo "===== ARCHITECTURE ====="
uname -m
echo

######################################
# HARDWARE MODEL
######################################
echo "===== HARDWARE MODEL ====="
if [ -f /proc/device-tree/model ]; then
  cat /proc/device-tree/model
else
  echo "N/A (likely x86 system)"
fi
echo

######################################
# CPU
######################################
echo "===== CPU ====="
lscpu || cat /proc/cpuinfo
echo

######################################
# MEMORY
######################################
echo "===== MEMORY ====="
free -h
echo

######################################
# STORAGE
######################################
echo "===== STORAGE ====="
lsblk
echo

######################################
# GPU / PLATFORM
######################################
echo "===== GPU / PLATFORM ====="

if [ -f /etc/nv_tegra_release ]; then
  echo "-- NVIDIA Jetson Platform --"
  cat /etc/nv_tegra_release
  echo
  echo "tegrastats available (Jetson runtime tool)"
elif command -v nvidia-smi >/dev/null 2>&1; then
  echo "-- NVIDIA GPU (x86) --"
  nvidia-smi
else
  echo "No NVIDIA GPU detected"
fi
echo

######################################
# CUDA / TENSORRT
######################################
echo "===== CUDA ====="
if command -v nvcc >/dev/null 2>&1; then
  nvcc --version
else
  echo "nvcc not found (runtime-only or CUDA not installed)"
fi
echo

echo "===== TENSORRT ====="
dpkg -l | grep -i tensorrt || echo "TensorRT not installed"
echo

######################################
# RASPBERRY PI
######################################
echo "===== RASPBERRY PI CHECK ====="
if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
  echo "Raspberry Pi detected"
  vcgencmd version || echo "vcgencmd not available"
else
  echo "Not a Raspberry Pi"
fi
echo

######################################
# VIDEO / MEDIA
######################################
echo "===== VIDEO / MEDIA ====="
ffmpeg -version | head -n 3 || echo "ffmpeg not installed"
echo

v4l2-ctl --list-devices || echo "v4l2 not available"
echo

gst-launch-1.0 --version || echo "gstreamer not installed"
echo

######################################
# DOCKER
######################################
echo "===== DOCKER ====="
docker version || echo "Docker not installed"
echo

echo "===== NVIDIA CONTAINER TOOLKIT ====="
dpkg -l | grep nvidia-container || echo "NVIDIA container toolkit not installed"
echo

######################################
# PYTHON / OPENCV
######################################
echo "===== PYTHON ====="
python3 --version || echo "Python3 not installed"
echo

echo "===== OPENCV ====="
python3 - << 'EOF' || echo "OpenCV not available"
try:
    import cv2
    print("OpenCV version:", cv2.__version__)
    cuda_count = cv2.cuda.getCudaEnabledDeviceCount() if hasattr(cv2, "cuda") else 0
    print("OpenCV CUDA devices:", cuda_count)
except Exception as e:
    print("OpenCV present but unusable:", e)
EOF
echo

######################################
# SYSTEM LIMITS
######################################
echo "===== SYSTEM LIMITS ====="
ulimit -a
echo

######################################
# AUTO CLASSIFICATION
######################################
echo "===== AUTO CLASSIFICATION ====="

ARCH=$(uname -m)

if grep -q "NVIDIA Jetson Nano" /proc/device-tree/model 2>/dev/null; then
  echo "Detected: Jetson Nano"
elif grep -q "Jetson" /proc/device-tree/model 2>/dev/null; then
  echo "Detected: Jetson (Xavier / Orin)"
elif grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
  echo "Detected: Raspberry Pi"
elif [[ "$ARCH" == "x86_64" ]]; then
  echo "Detected: x86_64 Desktop / Server"
elif [[ "$ARCH" == "aarch64" ]]; then
  echo "Detected: Generic ARM64 device"
else
  echo "Detected: Unknown hardware"
fi

echo
echo "=================================================="
echo " END OF REPORT"
echo " Saved as: $OUT"
echo "=================================================="
