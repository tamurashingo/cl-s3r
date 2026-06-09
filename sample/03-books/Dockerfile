FROM fukamachi/sbcl

RUN apt-get update && apt-get install -y git curl make automake autoconf texinfo libcurl4-openssl-dev zlib1g-dev

WORKDIR /app
COPY . /app

RUN mkdir -p /root/common-lisp/ && ln -s /app /root/common-lisp/cl-s3r
RUN sbcl --eval '(ql:quickload :cl-s3r)' --eval '(quit)'

ENV PATH="/root/.roswell/bin:$PATH"

RUN ros install rove
RUN ros run --eval '(ql:quickload :cl-s3r)' --eval '(quit)'

CMD ["--load", "sample/03-books/app.lisp", "--eval", "(cl-s3r.sample.books:run)"]
