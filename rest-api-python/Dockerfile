FROM python:3.12.4-bookworm
WORKDIR /home/vanilla_skies/projects/hsbc/ifc/rest-api-python
RUN python3 --version
COPY . .
RUN ls
RUN curl -L "https://nitric.io/install?version=latest" | bash
ENV PATH="/root/.nitric/bin:${PATH}"
RUN pip3 install pipenv watchdog nitric
RUN pipenv install --dev
# CMD ["nitric", "start"]
RUN nitric stack new dev aws
RUN nitric up
