FROM ruby:2.6.5-alpine3.11
ENV LANG C.UTF-8
RUN apk upgrade && \
    apk add --no-cache \
    bash \
    build-base \
    curl-dev \
    git \
    graphviz \
    imagemagick \
    imagemagick-dev \
    less \
    libxml2-dev \
    libxslt-dev \
    mysql-client \
    mysql-dev \
    nodejs \
    npm \
    openssl \
    readline \
    readline-dev \
    tar \
    ttf-freefont \
    tzdata \
    udev \
    wget \
    yaml \
    yaml-dev\
    zlib \
    zlib-dev

RUN npm install -g yarn

RUN gem install bundler
RUN gem update

ENV APP_HOME /rails-form-training
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ENV RAILS_ENV=production
ARG SECRET_KEY_BASE
ENV GEM_HOME=/bundle

ADD Gemfile* $APP_HOME/

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
  BUNDLE_JOBS=4 \
  BUNDLE_PATH=$GEM_HOME

ADD . $APP_HOME

RUN env RAILS_ENV=${RAILS_ENV} SECRET_KEY_BASE=${SECRET_KEY_BASE}  bundle exec rake assets:precompile
CMD ["bundle", "exec", "rails", "s", "puma", "-b", "0.0.0.0", "-p", "3000", "-e", "${RAILS_ENV}"]