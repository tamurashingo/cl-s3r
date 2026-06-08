FROM clfoundation/sbcl:latest

RUN apt-get update && apt-get install -y git curl

RUN curl -O https://beta.quicklisp.org/quicklisp.lisp && \
    sbcl --load quicklisp.lisp \
         --eval '(quicklisp-quickstart:install)' \
         --eval '(ql-util:without-prompting (ql:add-to-init-file))' \
         --eval '(quit)'

WORKDIR /app
COPY . /app

RUN mkdir -p /root/common-lisp/ && ln -s /app /root/common-lisp/cl-s3r
RUN sbcl --eval '(ql:quickload :cl-s3r)' --eval '(quit)'

CMD ["sbcl", "--load", "sample/03-books/app.lisp"]
