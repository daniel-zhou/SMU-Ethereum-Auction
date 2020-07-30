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

    bool public ended;

    mapping(address => Bid) public bids;

    address _owner = msg.sender;
    address public highestBidder;
    uint public highestBid;

    event AuctionStarted(uint time);
    event AuctionEnded(address winner, uint highestBid);

    // validate inputs to functions.
    // `onlyBefore` is applied to `bid` below:
    /// The new function body is the modifier's body where
    /// `_` is replaced by the old function body.
    modifier onlyBefore(uint _time) {require(now < _time, "Bid session has been closed");_;}
    modifier onlyAfter(uint _time) {require(now > _time, "Auction session has been closed");_;}

    constructor(
        uint _bidSessionSeconds,
        uint _revealSessionSeconds,
        IERC20 ercAddress
    ) public {
        //let biddingTime = _biddingTime * 1 minutes;
        //let revealTime = _revealTime * 1 minutes;
        token = ercAddress;

        auctionStartTime = now;
        bidCloseTime = auctionStartTime + _bidSessionSeconds;
        revealCloseTime = bidCloseTime + _revealSessionSeconds;
        emit AuctionStarted(auctionStartTime);
    }

    // Place a blinded bid with `_blindedBid` = keccak256(abi.encodePacked(value, random)).
    // The same address can place one bid. The latest one is valid.
    function bid(bytes32 _bidHash)
        public
        payable
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
        if (bidToValidate.blindedBid == keccak256(abi.encodePacked(_value, _random))) {
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
    function auctionEnd(address  _beneficiary)
        public
        payable
        onlyAfter(revealCloseTime)
    {
        require(!ended, "Auction hasn't started or had ended");
        // transfer the bid to the beneficiary
        require(token.transferFrom(_owner, _beneficiary, highestBid), "Complete");
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
    }
}