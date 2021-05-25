# REF: https://docs.docker.com/engine/reference/builder/
# REF: https://hub.docker.com/_/perl
FROM perl:5.34.0

# We point to the original repository for the image
LABEL org.opencontainers.image.source https://github.com/jonasbn/perl-app-yak

# We need C compiler and related tools
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends

# This is our yak work directory, we do not want to mix this
# with our staging area
WORKDIR /usr/src/app

# We use the canonical cpanfile, not the exact and tested fingerprint
# cpanfile.snapshot, this might change in the future if a snapshot file
# created on macOS makes sense on a Linux based image
COPY cpanfile .
RUN cpanm --installdeps .

# Installing yak
COPY . /usr/src/app

# This is our staging work directory
WORKDIR /tmp

# yak is only installed from repository not from CPAN, so we do not rely on a long
# distribution chain to build our Docker image
ENV PATH=$PATH:/usr/src/app/script

# This is our executable, it consumes all parameters passed to our container
ENTRYPOINT [ "yak", "--noconfig", "--nochecksums" ]
