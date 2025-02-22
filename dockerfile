# Usar Debian slim como base
FROM debian:bullseye-slim as builder

# Instalar dependências necessárias
RUN apt-get update && apt-get install -y \
    clang \
    llvm \
    make \
    cmake \
    g++ \
    libboost-all-dev \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libgmp-dev \
    libevent-dev \
    libsqlite3-dev \
    wget \
    apt-transport-https \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Instalar Rust (versão predefinida)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain 1.85.0 -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Instalar Go versão 1.20
RUN wget https://go.dev/dl/go1.20.12.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.20.12.linux-amd64.tar.gz \
    && rm go1.20.12.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Definir diretório de trabalho
WORKDIR /app

# Copiar o código do projeto para o container
COPY . .

ENV CC=clang CXX=clang++

# Habilitar todos os módulos definindo as flags CXXFLAGS
ENV CXXFLAGS="-DRUST_BITCOIN -DBTCD"


# Compilar os módulos necessários
RUN cd modules/rustbitcoin/rust_bitcoin_lib && cargo build --release
RUN cd modules/rustbitcoin && make
# RUN cd modules/rustminiscript/rust_miniscript_lib && cargo build --release
# RUN cd modules/rustminiscript && make
RUN cd modules/btcd && make
# RUN cd modules/ldk/ldk_lib && cargo build --release
# RUN cd modules/ldk && make
# RUN cd modules/bitcoin && make

# Construir o bitcoinfuzz
RUN make

# Definir comando padrão
CMD ["sh", "-c", "$FUZZ ./bitcoinfuzz"]
