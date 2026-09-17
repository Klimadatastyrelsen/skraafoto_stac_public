FROM python:3.8-slim-bookworm as production

# Any python libraries that require system libraries to be installed will likely
# need the following packages in order to build
RUN apt-get update \
    && apt-get install -y build-essential postgresql-client \
    && apt-get upgrade -y \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

WORKDIR /app

# Install stac_fastapi.types
COPY src /app
COPY constraints.txt /constraints.txt

ENV PATH=$PATH:/install/bin

# one pip invocation so the resolver must use the vendored packages and cannot
# swap in newer stac-fastapi.* dists from pypi
RUN mkdir -p /install && \
    pip install -c /constraints.txt \
    -e ./stac_fastapi/types \
    -e ./stac_fastapi/api \
    -e ./stac_fastapi/extensions \
    -e ./stac_fastapi/sqlalchemy[server]

CMD ["python","-m","uvicorn","stac_fastapi.sqlalchemy.app:app","--proxy-headers","--host","0.0.0.0","--port","8081","--timeout-keep-alive","65"]
