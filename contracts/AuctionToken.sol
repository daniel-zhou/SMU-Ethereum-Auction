pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";

contract AuctionToken is ERC20Mintable {

  string public constant name = "AuctionToken";
  string public constant symbol = "AUT";
  uint8 public constant decimals = 18;

  event Transfer(address indexed from, address indexed to, uint tokens);

}
