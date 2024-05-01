#! /bin/bash

set -ouex pipefail

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-cisco-openh264.repo

mkdir /tmp/rpms
mkdir -p /var/cache/rpms

# Install rpmfusion

RELEASE="$(rpm -E %fedora)"

RPMFUSION_MIRROR_RPMS="https://mirrors.rpmfusion.org"

curl -Lso /tmp/rpms/rpmfusion-free-release-${RELEASE}.noarch.rpm ${RPMFUSION_MIRROR_RPMS}/free/fedora/rpmfusion-free-release-${RELEASE}.noarch.rpm > /dev/null
curl -Lso /tmp/rpms/rpmfusion-nonfree-release-${RELEASE}.noarch.rpm ${RPMFUSION_MIRROR_RPMS}/nonfree/fedora/rpmfusion-nonfree-release-${RELEASE}.noarch.rpm > /dev/null

rpm-ostree install \
  /tmp/rpms/*.rpm \
  fedora-repos-archive

sed -i '0,/enabled=0/{s/enabled=0/enabled=1\npriority=110/}' /etc/yum.repos.d/rpmfusion-*-updates-testing.repo

# Install and build nvidia driver

NVIDIA_PACKAGE_NAME="nvidia"

rpm-ostree install \
  akmod-${NVIDIA_PACKAGE_NAME}* \
  xorg-x11-drv-${NVIDIA_PACKAGE_NAME}-{,cuda,devel,kmodsrc,power}*

KERNEL_VERSION="$(rpm -q "kernel" --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
NVIDIA_AKMOD_VERSION="$(basename "$(rpm -q "akmod-${NVIDIA_PACKAGE_NAME}" --queryformat '%{VERSION}-%{RELEASE}')" ".fc${RELEASE%%.*}")"
NVIDIA_LIB_VERSION="$(basename "$(rpm -q "xorg-x11-drv-${NVIDIA_PACKAGE_NAME}" --queryformat '%{VERSION}-%{RELEASE}')" ".fc${RELEASE%%.*}")"
NVIDIA_FULL_VERSION="$(rpm -q "xorg-x11-drv-${NVIDIA_PACKAGE_NAME}" --queryformat '%{EPOCH}:%{VERSION}-%{RELEASE}.%{ARCH}')"

akmods --force --kernels "${KERNEL_VERSION}" --kmod "${NVIDIA_PACKAGE_NAME}"

# If the module failed to build, print the log and exit with an error
modinfo /usr/lib/modules/${KERNEL_VERSION}/extra/${NVIDIA_PACKAGE_NAME}/nvidia{,-drm,-modeset,-peermem,-uvm}.ko.xz > /dev/null || \
(cat /var/cache/akmods/${NVIDIA_PACKAGE_NAME}/${NVIDIA_AKMOD_VERSION}-for-${KERNEL_VERSION}.failed.log && exit 1)