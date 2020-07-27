pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BlindAuction {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    IERC20 token;
    address payable public beneficiary;

    uint public biddingTime;
    uint public revealTime;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    mapping(address => Bid[]) public bids;

    address public highestBidder;
    uint public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingBidRefunds;

    event AuctionStarted(uint time);
    event AuctionEnded(address winner, uint highestBid);

    // validate inputs to functions.
    // `onlyBefore` is applied to `bid` below:
    /// The new function body is the modifier's body where
    /// `_` is replaced by the old function body.
    modifier onlyBefore(uint _time) {require(now < _time, "Bid session has been closed");_;}
    modifier onlyAfter(uint _time) {require(now > _time, "Auction session has been closed");_;}

    constructor(
        uint _biddingTime,
        uint _revealTime,
        IERC20 ercAddress,
        address payable _beneficiary
    ) public {
        biddingTime = _biddingTime;
        revealTime = _revealTime;
        token = ercAddress;
        beneficiary = _beneficiary;

        uint currentTime = block.timestamp;
        biddingEnd = currentTime + biddingTime;
        revealEnd = biddingEnd + revealTime;
        emit AuctionStarted(currentTime);
    }

    // Place a blinded bid with `_blindedBid` = keccak256(abi.encodePacked(value, fake, secret)).
    // The sent is only refunded if the bid is correctly revealed in the revealing phase.
    // The bid is valid if "fake" is false and valid "value".
    // if bid is not the exact amount or "fake" is true, unrevealed bid.
    // The same address can place multiple bids.
    function bid(uint _value, bytes32 _random)
        public
        payable
        onlyBefore(biddingEnd)
    {
        bytes32 blindedBidHash = keccak256(abi.encodePacked(_value, _random));
        bids[msg.sender].push(
            Bid({
                blindedBid: blindedBidHash,
                deposit: msg.value
            })
        );
    }

    /// Withdraw bid that was overbid.
    function withdraw() public {
        uint amount = pendingBidRefunds[msg.sender];
        if (amount > 0) {
            // clear bidRefunds to zero because the recipient
            // can call this function again.
            pendingBidRefunds[msg.sender] = 0;

            msg.sender.transfer(amount);
        }
    }

    /// Reveal all blinded bids. Refund for all correctly blinded invalid bids,
    /// except for the totally highest.
    function reveal(
        uint[] memory _values,
        bytes32[] memory _randoms
    )
        public
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
    {
        uint length = bids[msg.sender].length;
        require(_values.length == length, "values length is not equal");
        require(_randoms.length == length, "randoms length is not equal");

        uint depositRefund;
        for (uint i = 0; i < length; i++) {
            Bid storage bidToValidate = bids[msg.sender][i];
            (uint value, bytes32 secret) = (_values[i], _randoms[i]);
            if (bidToValidate.blindedBid != keccak256(abi.encodePacked(value, secret))) {
                // Bid was not successfully revealed.
                // Do not refund deposit.
                continue;
            }
            depositRefund += bidToValidate.deposit;
            if (!fake && bidToValidate.deposit >= value) {
                // valid revealed bid. place for bidding.
                if (placeBid(msg.sender, value)) {
                    // successful bid. deduct bid value.
                    depositRefund -= value;
                }
            }
            // clear the bid after being revealed.
            bidToValidate.blindedBid = bytes32(0);
        }
        // send back the balance of desposit after processing bid.
        msg.sender.transfer(depositRefund);
        //token.transferFrom(this, msg.sender.address, depositRefund);
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
            pendingBidRefunds[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd()
        public
        onlyAfter(revealEnd)
    {
        require(!ended, "Auction hasn't started or had ended");
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }
}