FROM ruby:2.3

WORKDIR /

COPY . /

CMD gem install bundle;
RUN bundle;
