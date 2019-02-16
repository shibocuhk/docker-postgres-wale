FROM postgres:11

MAINTAINER Luke Smith

RUN apt-get update \
   && apt-get install -y \
   postgresql-server-dev-$PG_MAJOR \
   make libc-dev g++ git cmake curl wget ca-certificates openssl \
   && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
   #download wal-g
   && wget https://github.com/wal-g/wal-g/releases/download/v0.2.4/wal-g.linux-amd64.tar.gz \
   && tar -zxvf wal-g.linux-amd64.tar.gz \
   && chmod +x /wal-g \
   # install zhparser
   && wget http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2 \
   && tar -jxvf scws-1.2.3.tar.bz2 \
   && cd scws-1.2.3  \
   && ./configure \
   && make install \
   && cd / \
   && git clone https://github.com/amutu/zhparser.git \
   && cd zhparser \
   && make && make install \
   # cleanup
   && cd / \
   && apt-get purge -y gcc make libc-dev postgresql-server-dev-$PG_MAJOR g++ git cmake curl\
   && apt-get autoremove -y \
   && rm -rf zhparser \
   && rm -rf scws-1.2.3

# Change the entrypoint so wale will always be setup, even if the data dir already exists
COPY backup /
COPY fix-acl.sh setup-wal.sh init-dict.sh /docker-entrypoint-initdb.d/

CMD ["postgres"] 