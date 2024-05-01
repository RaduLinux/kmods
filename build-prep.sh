#! /bin/bash

set -ouex pipefail

mkdir -p /var/lib/alternatives

rpm-ostree install \
  kernel-devel \
  kernel-devel-matched \
  akmods \
  mock \
  binutils