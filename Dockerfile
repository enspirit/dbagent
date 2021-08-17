FROM ruby:2.7

ENV LANG C.UTF-8
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN addgroup --gid 1000 --system app \
  && adduser --uid 1000 --system --gid 1000 app \
  && mkdir -p /home/app \
  && chown app:app -R /home/app

ENV HOME /home/app
WORKDIR /home/app

RUN  apt-get update \
  && apt-get install -qq --no-install-recommends --fix-missing \
      vim \
      postgresql-client \
      default-jre \
      graphviz \
      iputils-ping  \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER app

COPY --chown=app:app Gemfile Gemfile.lock /home/app/
RUN cd /home/app && bundle install --path=vendor/bundle

RUN mkdir -p /home/app/vendor && \
    curl -L https://jdbc.postgresql.org/download/postgresql-42.2.23.jar -o /home/app/vendor/postgresql-42.2.23.jar && \
    curl -L https://github.com/schemaspy/schemaspy/releases/download/v6.1.0/schemaspy-6.1.0.jar -o /home/app/vendor/schemaspy-6.1.0.jar

COPY --chown=app:app . /home/app

CMD bundle exec rackup -p 9292 -o 0.0.0.0
