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
   # install jieba
   && git clone https://github.com/jaiminpan/pg_jieba  \
   && cd /pg_jieba  \
   && git submodule update --init --recursive \
   && cd /pg_jieba \
   && mkdir -p build \
   && cd build \
   && curl -L https://raw.githubusercontent.com/Kitware/CMake/ce629c5ddeb7d4a87ac287c293fb164099812ca2/Modules/FindPostgreSQL.cmake > $(find /usr -name "FindPostgreSQL.cmake") \
   && cmake -DPostgreSQL_TYPE_INCLUDE_DIR=/usr/include/postgresql/11/server .. \
   && make \
   && make install \ 
   # cleanup
   && cd / \
   && apt-get purge -y gcc make libc-dev postgresql-server-dev-$PG_MAJOR g++ git cmake curl\
   && apt-get autoremove -y \
   && rm -rf \
      /pg_jieba



# Change the entrypoint so wale will always be setup, even if the data dir already exists
COPY backup /
COPY fix-acl.sh setup-wal.sh init-dict.sh /docker-entrypoint-initdb.d/

CMD ["postgres"]