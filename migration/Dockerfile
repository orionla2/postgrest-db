FROM docteurklein/sqitch
ENV PGHOST postgresql_test
ENV PGDATABASE postgres
ENV PGUSER postgres
ENV PGPASSWORD 1q2w3e4r
RUN apt-get update \
	&& apt-get install -y apt-utils \
	&& apt-get install -y libdbd-pg-perl postgresql-client \
	&& cpan App::cpanminus \
	&& cpanm DBD::Pg \
	&& apt-get install -y sqitch \
	&& groupadd -r postgres --gid=999 \
	&& useradd -r -g postgres --uid=999 postgres 
ENTRYPOINT ["/bin/bash"]
