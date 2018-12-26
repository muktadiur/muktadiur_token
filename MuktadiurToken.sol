pragma solidity >=0.4.22 <0.6.0;

import "./TokenERC20.sol";

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Sender is not authorized.");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner, "Sender is not authorized.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract MuktadiurToken is Owned, TokenERC20 {
    uint256 public sellPrice;
    uint256 public buyPrice;
    mapping (address => bool) public frozenAccount;
    
    // This generates a public event on the blockchain that will notify clients.
    event FrozenFunds(address target, bool frozen);

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    // Internal transfer, only can be called by this contract.
    function _transfer(address _from, address _to, uint _value) internal {
        require(
            _to != address(0x0),
            "Prevent transfer to 0x0 address."
        );
        require (balanceOf[_from] >= _value, "Check if the sender has enough");
        require (
            balanceOf[_to] + _value >= balanceOf[_to],
            "Check for overflows"
        ); 
        require(!frozenAccount[_from], "sender is frozen");
        require(!frozenAccount[_to], "recipient is frozen");

        balanceOf[_from] -= _value;                         
        balanceOf[_to] += _value;                           
        emit Transfer(_from, _to, _value);
    }

    function mintToken(address target, uint256 mintedAmount) public onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), owner, mintedAmount);
        emit Transfer(owner, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() public payable {
        uint amount = msg.value / buyPrice;               
        _transfer(owner, msg.sender, amount);              
    }

    function sell(uint256 amount) public {
        require(
            owner.balance >= amount * sellPrice, 
            "Contract does not have enough ether to buy"
        );   
        _transfer(msg.sender, owner, amount); 
        // It's important to do this last to avoid recursion attacks             
        msg.sender.transfer(amount * sellPrice);          
    }
}
