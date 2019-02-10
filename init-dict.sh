  echo "timezone = 'Asia/Shanghai'" >> /var/lib/postgresql/data/postgresql.conf
  echo "shared_preload_libraries = 'pg_jieba.so'" >> /var/lib/postgresql/data/postgresql.conf