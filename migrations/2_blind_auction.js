const BlindAuction = artifacts.require("BlindAuction");
const AuctionToken = artifacts.require("AuctionToken");

module.exports = function(deployer, networks, accounts) {
  let platform = accounts[0];
  let auctionToken;
  deployer.deploy(AuctionToken, {from: platform}).then((_inst) => {
    auctionToken = _inst;
    // 120 seconds for bidding, and 120 seconds for revealing
    return deployer.deploy(BlindAuction, 120, 120, auctionToken.address, ,{from: platform});
  })
};
