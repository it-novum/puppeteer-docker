# puppeteer-docker
Docker container to render PDF files using puppeteer

## Build the Docker image
```
docker build . -t openitcockpit/puppeteer -f Dockerfile
```

## Run Container (for developments)
```
docker run --rm -it --init -p 8084:8084 openitcockpit/puppeteer /bin/bash
```

## curl Test command
```
curl -X POST -H "Content-Type: text/plain" --data "<\!DOCTYPE html><html><head><title>PDF test</title></head><body><p>It works!</p></body></html>" http://127.0.0.1:8084/pdf --output result.pdf
```

## Docker integration tests
The repository includes endpoint integration tests that run fully against the Docker container.

Run only area chart test:
```
./src/test/test_area_chart_docker.sh
```

Run only PDF test:
```
./src/test/test_pdf_docker.sh
```

Run all tests:
```
./src/test/run_all_docker_tests.sh
```

Force image rebuild before test run:
```
./src/test/run_all_docker_tests.sh --rebuild
```


docker run --rm -it --init -p 8084:8084 -v /opt/openitc/frontend/webroot:/opt/openitc/frontend/webroot:ro  openitcockpit/puppeteer /bin/bash


https://stackoverflow.com/questions/47587352/opening-local-html-file-using-puppeteer




/opt/openitc/frontend/

docker run --rm -it --init -p 7084:8084 -v /opt/openitc/frontend/:/opt/openitc/frontend/:ro  openitcockpit/puppeteer /bin/bash

## Debugging
To debug this, open the `area_chart_template.html` file in your web browser. You can use console.log and dev tools as you are used to it.