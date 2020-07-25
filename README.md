# Ethereum Auction Example Projet

This is a simple ethereum sample for blind auction. 

# Installation

Set the system using:
```
npm install
```
which will pull in dependancies.

# Running the system

Start an instance of ethereum, either using your `geth` node, or simulating it using `ganache` or `ganache-cli`.
Make sure that `truffle-config.js` has the correct parameters.

Deploy the code using `truffle migrate`.

Start the UI inside the `app` folder:
```
cd app
nodejs server.js
```
and open (http://localhost:8080) in your browser.

This is a very simple server that only serves static content. It serves the `app` folder, and also the `build/contracts` folder, so that the build artifacts are accessible to the javascript.

The UI is designed to work with metamask or other injected web3 client(eg. mobile ethereum app).
It will perform a one-time request to connect to your metamask the first time it runs.
