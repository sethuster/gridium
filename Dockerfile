FROM ruby:2.3

WORKDIR /

COPY . /

#a hack to migrate env variables
ENV S3_ACCESS_KEY_ID AKIAIYXNSM4UJVLYOK2Q
ENV S3_SECRET_ACCESS_KEY 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
ENV S3_DEFAULT_REGION us-east-1
ENV S3_ROOT_BUCKET sg-qe-artifacts

CMD gem install bundle;
RUN bundle;
