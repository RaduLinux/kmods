FROM quay.io/fedora-ostree-desktops/silverblue:40 as builder

RUN rpm-ostree install \
  kernel-devel \
  kernel-devel-matched \
  akmods \
  mock \
  binutils

COPY build-nvidia-kmod.sh /tmp/

RUN /tmp/build-nvidia-kmod.sh

RUN for RPM in $(find /var/cache/akmods/ -type f -name \*.rpm); do \
  cp $RPM /var/cache/rpms/; \
  done

RUN find /var/cache/rpms

FROM scratch

COPY --from=builder /var/cache/rpms /rpms