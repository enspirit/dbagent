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

COPY --chown=app:app Gemfile Gemfile.lock /home/app/
RUN cd /home/app && bundle install

COPY --chown=app:app . /home/app

CMD bundle exec rackup -p 80
