FROM postgres:11

MAINTAINER Luke Smith

RUN apt-get update  \
   && apt-get install -y python3-pip python3.4 \
   lzop pv daemontools postgresql-server-dev-$PG_MAJOR \
   make libc-dev g++ git cmake curl ca-certificates openssl && \
   pip3 install wal-e[aws] && \
   mkdir -p /etc/wal-e.d/env && \
   chown -R postgres:postgres /etc/wal-e.d && \
   apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN git clone https://github.com/jaiminpan/pg_jieba \
  && cd /pg_jieba \
  && git submodule update --init --recursive 

RUN cd /pg_jieba \
  && mkdir -p build \
  && cd build \
  && curl -L https://raw.githubusercontent.com/Kitware/CMake/ce629c5ddeb7d4a87ac287c293fb164099812ca2/Modules/FindPostgreSQL.cmake > $(find /usr -name "FindPostgreSQL.cmake") \
  && cmake -DPostgreSQL_TYPE_INCLUDE_DIR=/usr/include/postgresql/11/server .. \
  && make \
  && make install \
  && apt-get purge -y gcc make libc-dev postgresql-server-dev-$PG_MAJOR g++ git cmake curl\
  && apt-get autoremove -y \
  && rm -rf \
    /pg_jieba


# Change the entrypoint so wale will always be setup, even if the data dir already exists
COPY backup /
COPY fix-acl.sh setup-wale.sh init-dict.sh /docker-entrypoint-initdb.d/

CMD ["postgres"]