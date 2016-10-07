FROM ubuntu:14.04
ENV DEBIAN_FRONTEND noninteractive
MAINTAINER sampleuser
RUN apt-get update && \
    apt-get install -y  puppet

ADD nginx /etc/puppet/modules/
ADD site.pp /etc/puppet/manifest
CMD ["puppet agent -t --debug"]
EXPOSE 80
