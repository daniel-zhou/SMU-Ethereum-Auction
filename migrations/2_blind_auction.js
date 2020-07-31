const BlindAuction = artifacts.require("BlindAuction");
const AuctionToken = artifacts.require("AuctionToken");

module.exports = function(deployer, networks, accounts) {
  let platform = accounts[0];
  let auctionToken;
  deployer.deploy(AuctionToken, {from: platform}).then((_inst) => {
    auctionToken = _inst;
    for (var i=0; i< accounts.length; i++) {
      auctionToken.mint(accounts[i], 1000);
    }
    //auctionToken.mint(0x579351f39be9C29b01589bce8E02E5e5e4AE0a32, 10000);
    // 120 seconds for bidding, and 120 seconds for revealing
    return deployer.deploy(BlindAuction, auctionToken.address, {from: platform});
  })
};
