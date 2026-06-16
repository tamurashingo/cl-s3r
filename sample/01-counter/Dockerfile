FROM fukamachi/sbcl

RUN apt-get update && apt-get install -y git curl make automake autoconf texinfo libcurl4-openssl-dev zlib1g-dev

WORKDIR /app
# 親ディレクトリのソースを含める必要があるため、ビルドコンテキストをプロジェクトルートにする想定
COPY . /app

RUN mkdir -p /root/common-lisp/ && ln -s /app /root/common-lisp/cl-s3r
RUN sbcl --eval '(ql:quickload :cl-s3r)' --eval '(quit)'

ENV PATH="/root/.roswell/bin:$PATH"

RUN ros install rove
# rove が使う roswell 環境に cl-s3r をプリロードする
RUN ros run --eval '(ql:quickload :cl-s3r)' --eval '(quit)'

RUN ros install /app/roswell/s3rup.ros

ENTRYPOINT []
CMD ["s3rup", "/app/sample/01-counter/01-counter.asd"]
