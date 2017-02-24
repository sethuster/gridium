FROM ruby:2.3

WORKDIR /gridium

COPY . /gridium

CMD gem install bundle;
