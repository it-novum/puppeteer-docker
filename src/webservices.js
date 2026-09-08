/**
 * Copyright (C) 2015-2025   <it-novum GmbH>
 * Copyright (C) 2025-today  <AVENDIS GmbH>
 * Licensed under the MIT License
 *
 *
 * openITCOCKPIT Node.js based web services
 *
 * Current API Endpoints:
 * - [POST] /pdf
 *      Accept: application/json
 *      Return: application/pdf
 * - [POST] /area_chart (deprecated)
 *      Accept: application/json
 *      Return: application/png
 */

 'use strict';

 const puppeteer = require('puppeteer');
 const express = require('express');
 const bodyParser = require('body-parser');
 const fs = require('fs');
 var temp = require("temp").track();
 const util = require('util');
 
 var app = express();
 app.use(bodyParser.text({limit: '500mb'}));
 app.use(bodyParser.json({limit: '500mb'}));
 app.use(bodyParser.urlencoded({limit: '500mb', extended: true}));
 
 app.post('/pdf', async function(request, response){
    let browser;
     try{
         //console.log(request.body);     // json data

        if (!request.body || typeof request.body !== 'object') {
            response.status(400).json({error: 'Request body must be a JSON object'});
            return response;
        }
 
         const html = request.body.html;
        const settings = request.body.settings && typeof request.body.settings === 'object'
            ? request.body.settings
            : {};

        if (typeof html !== 'string' || html.length === 0) {
            response.status(400).json({error: 'Missing or invalid "html" payload'});
            return response;
        }
 
         // .html file suffix is important. Otherwise puppeteer will render the file as plaintext
         var tmpFile = temp.openSync({suffix: '.html'});
         fs.writeFileSync(tmpFile.path,
             html,
             {
                 encoding: "utf8",
                 flag: "w+",
                 mode: 0o666
             });
 
 
         // Create new Chrome Browser
         // --no-sandbox is bad and unsecure, but this is running inside of a Docker Container and only
         // rendering our own trusted HTML so we don't really need to care about security anyway
        browser = await puppeteer.launch({
             args: [
                 '--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage',
                 //'--disable-web-security', '--font-render-hinting=none', '--headless', '--force-color-profile=srgb'
             ],
         });
 
 
         const page = await browser.newPage();
 
         await page.goto('file://' + tmpFile.path, {
             waitUntil: 'networkidle0', //networkidle2
         });
 
         // This does not allow to load local CSS files
         // So we HAVE to store the HTML in a tmp file, because than we can use local CSS.
         // For the love of god - why Google?
         //await page.setContent(html, {
         //    waitUntil: 'networkidle0',
         //});
 
         //await page.emulateMediaType('screen');
         // page.pdf() is currently supported only in headless mode.
         // @see https://bugs.chromium.org/p/chromium/issues/detail?id=753118
         const pdfBuffer = await page.pdf(
             settings
         );
 
         response.writeHead(200, {'Content-Type': 'application/pdf'});
         response.end(pdfBuffer, 'binary');
     }catch(e){
         console.error(e);
        if (!response.headersSent) {
            response.status(500).json({error: 'Failed to render PDF'});
        }
    }finally{
        if (browser) {
            await browser.close();
        }
        temp.cleanup();
     }

     return response;
 });
 
 
 app.post('/area_chart', async function(request, response){
    let browser;
     try{
         //console.log(request.body);     // json data
        if (!request.body || typeof request.body !== 'object') {
            response.status(400).json({error: 'Request body must be a JSON object'});
            return response;
        }

         var requestBody = request.body;
         //console.log(util.inspect(requestBody, false, null, true /* enable colors */))
 
 
         // Create new Chrome Browser
         // --no-sandbox is bad and unsecure, but this is running inside of a Docker Container and only
         // rendering our own trusted HTML so we don't really need to care about security anyway
        browser = await puppeteer.launch({
             args: [
                 '--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage',
                 //'--disable-web-security', '--font-render-hinting=none', '--headless', '--force-color-profile=srgb'
             ],
         });
 
 
         const page = await browser.newPage();
 
         await page.goto('file:///src/area_chart_template.html', {
             waitUntil: 'networkidle0', //networkidle2
         });
 
         // Pass requestBody to area_chart_template.html and call renderChart() function of area_chart_template.html
         await page.evaluate((requestBody) => {
             window.renderChart(requestBody)
         }, requestBody); // 1. pass variable as an argument
 
 
         const chartDiv = await page.$('#chart')
         const pngBuffer = await chartDiv.screenshot();
 
         response.writeHead(200, {'Content-Type': 'image/png'});
         response.end(pngBuffer, 'binary');
     }catch(e){
         console.error(e);
        if (!response.headersSent) {
            response.status(500).json({error: 'Failed to render area chart'});
        }
    }finally{
        if (browser) {
            await browser.close();
        }
     }

     return response;
 });
 
 // Start the Web Server
 app.listen(8084, '0.0.0.0');
 