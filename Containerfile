FROM quay.io/fedora-ostree-desktops/silverblue:40 as builder

COPY build-*.sh /tmp/

RUN /tmp/build-prep.sh

RUN /tmp/build-nvidia-kmod.sh

RUN for RPM in $(find /var/cache/akmods/ -type f -name \*.rpm); do \
  cp $RPM /var/cache/rpms/; \
  done

RUN find /var/cache/rpms

FROM scratch

COPY --from=builder /var/cache/rpms /rpms