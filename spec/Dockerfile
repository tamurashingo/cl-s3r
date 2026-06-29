FROM fukamachi/sbcl

RUN apt-get update && apt-get install -y \
    git curl make automake autoconf texinfo \
    libcurl4-openssl-dev zlib1g-dev

WORKDIR /app

COPY . /app/cl-s3r

RUN mkdir -p /root/common-lisp/ && \
    ln -s /app/cl-s3r /root/common-lisp/cl-s3r

ENV PATH="/root/.roswell/bin:$PATH"

RUN ros install /app/cl-s3r
RUN ros install tamurashingo/spec-sheet

ENTRYPOINT []
CMD ["spec-sheet", "/app/cl-s3r/spec/src/spec-loader.lisp"]
