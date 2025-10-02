FROM ruby:3.3

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

COPY --chown=app:app Gemfile Gemfile.lock dbagent.gemspec /home/app/
COPY --chown=app:app lib/db_agent/version.rb /home/app/lib/db_agent/version.rb
RUN cd /home/app && bundle install --path=vendor/bundle

RUN mkdir -p /home/app/vendor && \
    curl -L https://jdbc.postgresql.org/download/postgresql-42.7.6.jar -o /home/app/vendor/postgresql-42.7.6.jar && \
    curl -L https://github.com/schemaspy/schemaspy/releases/download/v6.2.4/schemaspy-6.2.4.jar -o /home/app/vendor/schemaspy-6.2.4.jar

COPY --chown=app:app . /home/app

CMD bundle exec puma -t 1:1 -p 9292
