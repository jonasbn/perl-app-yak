# check=skip=InvalidDefaultArgInFrom

# REF: https://docs.docker.com/engine/reference/builder/
# REF: https://hub.docker.com/_/perl
# REF: https://github.com/Perl/docker-perl

# Pinned by digest so the build is reproducible; bump the tag/digest pair
# together when moving to a new perl/Debian release.
ARG BASE_IMAGE=perl:5.44.0-slim-trixie@sha256:c9aac2fcb8612b25b818df998413423eecf15d8d5175c98d1c10a069ac7e7f8f
FROM ${BASE_IMAGE}

# We point to the original repository for the image
LABEL org.opencontainers.image.source="https://github.com/jonasbn/perl-app-yak"
LABEL org.opencontainers.image.base.name="registry.hub.docker.com/library/perl:5.44.0-slim-trixie"

# build-essential: required to compile Net::SSLeay (pulled in by LWP::Protocol::https);
# the slim base image ships without a C compiler
# libssl-dev: required to compile Net::SSLeay (pulled in by LWP::Protocol::https)
# ca-certificates: needed for TLS certificate verification at runtime
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libssl-dev \
        ca-certificates \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# This is our yak work directory, we do not want to mix this
# with our staging area
WORKDIR /usr/src/app

# We use the canonical cpanfile, not the exact and tested fingerprint
# cpanfile.snapshot, this might change in the future if a snapshot file
# created on macOS makes sense on a Linux based image
COPY cpanfile .
# --notest: skip module tests during install; LWP::Protocol::https tests make
# live HTTPS connections that are unavailable inside a Docker build context
RUN cpanm --notest --installdeps .

# Installing yak
COPY . /usr/src/app

# This is our staging work directory
WORKDIR /tmp

# yak is only installed from repository not from CPAN, so we do not rely on a long
# distribution chain to build our Docker image
ENV PATH=$PATH:/usr/src/app/script

# This is our executable, it consumes all parameters passed to our container
ENTRYPOINT [ "yak", "--noconfig", "--nochecksums" ]
