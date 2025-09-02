# Base layer with Debian and C++ build tools
FROM --platform=linux/amd64 debian:bullseye-slim as cpp-builder

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        autoconf \
        automake \
        libtool \
        pkg-config \
        zlib1g-dev \
        make \
        curl \
        g++ && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /protobuf

# Copy source code
COPY *.txt *.sh *.ac *.am *.pc.in ./
COPY objectivec/ objectivec/
COPY kokoro/ kokoro/
COPY python/ python/
COPY protoc-artifacts/ protoc-artifacts/
COPY .github/ .github/
COPY src/ src/
COPY docs/ docs/
COPY benchmarks/ benchmarks/
COPY php/ php/
COPY csharp/ csharp/
COPY util/ util/
COPY m4/ m4/
COPY third_party/ third_party/
COPY cmake/ cmake/
COPY ruby/ ruby/
COPY examples/ examples/
COPY conformance/ conformance/
COPY js/ js/
COPY editors/ editors/
COPY third_party/ third_party/

# Build C++ protobuf following README.txt instructions
RUN ./autogen.sh
RUN ./configure --prefix=/protobuf/dist
RUN make -j 4
RUN make check -j 4
RUN make install

# Java layer with OpenJDK 8 and Maven 3.3.9
FROM --platform=linux/amd64 openjdk:8-jdk

ENV MAVEN_VERSION=3.3.9
ENV MAVEN_HOME=/opt/maven
ENV PATH=${MAVEN_HOME}/bin:${PATH}

# Install Maven
RUN apt-get update && \
    apt-get install -y wget tar && \
    wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    tar -xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt && \
    mv /opt/apache-maven-${MAVEN_VERSION} ${MAVEN_HOME} && \
    rm apache-maven-${MAVEN_VERSION}-bin.tar.gz

WORKDIR /app
COPY *.txt *.sh *.ac *.am *.pc.in ./
COPY objectivec/ objectivec/
COPY kokoro/ kokoro/
COPY python/ python/
COPY protoc-artifacts/ protoc-artifacts/
COPY .github/ .github/
COPY src/ src/
COPY docs/ docs/
COPY benchmarks/ benchmarks/
COPY php/ php/
COPY csharp/ csharp/
COPY util/ util/
COPY m4/ m4/
COPY third_party/ third_party/
COPY cmake/ cmake/
COPY ruby/ ruby/
COPY examples/ examples/
COPY conformance/ conformance/
COPY js/ js/
COPY java/ java/
COPY editors/ editors/
COPY third_party/ third_party/

# Copy protoc binary from C++ builder
COPY --from=cpp-builder /protobuf/dist/bin/protoc /app/src/protoc
COPY --from=cpp-builder /protobuf/dist/lib/* /usr/lib/


WORKDIR /app/java
RUN mvn test
RUN mvn package
