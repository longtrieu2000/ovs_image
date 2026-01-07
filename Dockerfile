# =========================
# Stage 1: build ovs + USDT
# =========================
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /build

RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    python3 \
    libc6-dev \
    libnuma-dev \
    libbpf-dev \
    libatomic1 \
    libcap-ng-dev \
    libssl-dev \
    libnl-3-dev \
    libnl-genl-3-dev \
    systemtap-sdt-dev \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY ovs/ /build/ovs
WORKDIR /build/ovs

RUN ./boot.sh && \
    ./configure \
      --enable-usdt-probes \
      --prefix=/usr/local \
      --sysconfdir=/etc \
      --localstatedir=/var \
    && make -j$(nproc)

RUN make DESTDIR=/ovs-install install


# =========================
# Stage 2: runtime vswitchd
# =========================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    libnuma1 \
    libbpf0 \
    libatomic1 \
    libcap-ng0 \
    libssl3 \
    libnl-3-200 \
    libnl-genl-3-200 \
    iproute2 \
    procps \
    ca-certificates \
    binutils \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /ovs-install/ /

RUN mkdir -p /var/run/openvswitch

CMD ["/usr/local/sbin/ovs-vswitchd", \
     "--pidfile", \
     "--log-file", \
     "unix:/var/run/openvswitch/db.sock"]
