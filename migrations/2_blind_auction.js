const BlindAuction = artifacts.require("BlindAuction");
const AuctionToken = artifacts.require("AuctionToken");

module.exports = function(deployer, networks, accounts) {
  let platform = accounts[0];
  let diceInstance;
  let auctionToken;
  let fee = 100;
  deployer.deploy(AuctionToken, {from: platform}).then((_inst) => {
    auctionToken = _inst;
    return deployer.deploy(BlindAuction, auctionToken.address, {from: platform});
  })
};
