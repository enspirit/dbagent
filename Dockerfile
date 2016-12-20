FROM phusion/passenger-ruby23

# Set correct environment variables and workdir
ENV HOME /home/app
WORKDIR /home/app

# Install a few handy tools
RUN apt-get update
RUN apt-get install -y vim
RUN apt-get install -y postgresql-client-9.5
RUN apt-get install -y default-jre
RUN apt-get install -y graphviz

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install dependencies through bundler
COPY Gemfile /home/app
RUN cd /home/app && bundle install

# Start nginx
RUN rm -f /etc/service/nginx/down

# Install nginx configuration
RUN rm /etc/nginx/sites-enabled/default
ADD config/webapp.conf /etc/nginx/sites-enabled/webapp.conf
ADD config/postgres-env.conf /etc/nginx/main.d/postgres-env.conf

# Install the app
RUN mkdir -p /home/app/public
COPY . /home/app

# I'm the maintainer!
MAINTAINER blambeau@enspirit.be

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]
