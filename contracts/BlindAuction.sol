pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./AuctionToken.sol";

contract BlindAuction {
    struct Bid {
        bytes32 blindedBid;
    }

    IERC20 token;

    uint public auctionStartTime;
    uint public bidCloseTime;
    uint public revealCloseTime;
    bytes32 public bidHashVallue;
    address public beneficiary;
    bool public ended;

    mapping(address => Bid) public bids;

    address _owner = msg.sender;
    address highestBidder;
    uint highestBid;

    event AuctionStarted(uint time);
    event AuctionEnded(address winner, uint highestBid);

    // validate inputs to functions.
    // `onlyBefore` is applied to `bid` below:
    /// The new function body is the modifier's body where
    /// `_` is replaced by the old function body.
    modifier onlyBefore(uint _time) {require(now < _time, "session time point has been passed");_;}
    modifier onlyAfter(uint _time) {require(now > _time, "session time point has not been reached");_;}

    constructor(
        IERC20 ercAddress,
        address _beneficiary
    ) public {
        token = ercAddress;
        beneficiary = _beneficiary;
    }

    function auctionStart(
        uint _bidSessionSeconds,
        uint _revealSessionSeconds
    )
        public
    {
        require(_owner == msg.sender, "Only deployer can start auction");
        highestBid = uint(0);
        highestBidder = address(0);
        ended = false;
        auctionStartTime = now;
        bidCloseTime = auctionStartTime + _bidSessionSeconds;
        revealCloseTime = bidCloseTime + _revealSessionSeconds;

        emit AuctionStarted(auctionStartTime);
    }

    // Place a blinded bid with `_blindedBid` = keccak256(abi.encodePacked(value, random)).
    // The same address can place one bid. The latest one is valid.
    function bid(bytes32 _bidHash)
        public
        onlyBefore(bidCloseTime)
    {
        bids[msg.sender] = Bid({
            blindedBid: _bidHash
        });
    }

    /// Reveal all blinded bids. Refund for all correctly blinded invalid bids,
    /// except for the totally highest.
    function reveal(
        uint _value,
        bytes32 _random
    )
        public
        onlyAfter(bidCloseTime)
        onlyBefore(revealCloseTime)
    {
        Bid storage bidToValidate = bids[msg.sender];
        bidHashVallue = keccak256(abi.encodePacked(_value));
        if (bidToValidate.blindedBid == bidHashVallue) {
            // valid revealed bid. place for bidding.
            placeBid(msg.sender, _value);
            // clear the bid after being revealed.
            bidToValidate.blindedBid = bytes32(0);
        }
    }

    // place bid to see if it is highest one or not.
    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            // Refund the previously highest bidder.
            require(token.transferFrom(_owner, highestBidder, highestBid), "Refund");
            //token.Transfer(_owner, highestBidder, highestBid);
        }
        highestBid = value;
        highestBidder = bidder;
        // transfer the bid from the current highest bidder
        require(token.transferFrom(highestBidder, _owner, highestBid), "Bid");
        return true;
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd()
        public
        onlyAfter(revealCloseTime)
    {
        require(!ended, "Auction hasn't started or had ended");
        require(_owner == msg.sender, "Only deployer can end auction");
        //require(token.transferFrom(_owner, beneficiary, highestBid), "failed to pass to beneficiary");
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
    }

    function getHighestBidder()
        public
        onlyAfter(revealCloseTime)
        view
        returns (address)
    {
        return highestBidder;
    }

    function getHighestBid()
        public
        onlyAfter(revealCloseTime)
        view
        returns (uint)
    {
        return highestBid;
    }
}