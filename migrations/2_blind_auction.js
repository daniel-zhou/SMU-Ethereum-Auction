const BlindAuction = artifacts.require("BlindAuction");
const AuctionToken = artifacts.require("AuctionToken");

module.exports = function(deployer, networks, accounts) {
  let platform = accounts[0];
  let auctionToken;
  let beneficiary;
  deployer.deploy(AuctionToken, {from: platform}).then((_inst) => {
    auctionToken = _inst;
    for (var i=0; i< accounts.length; i++) {
      auctionToken.mint(accounts[i], 1000);
    }
    // set the last in accounts as beneficiary
    beneficiary = accounts[accounts.length - 1];
    // 120 seconds for bidding, and 120 seconds for revealing
    return deployer.deploy(BlindAuction, auctionToken.address, beneficiary, {from: platform});
  })
};
