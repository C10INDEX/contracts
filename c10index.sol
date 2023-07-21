// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract C10Token is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("C10index", "C10") {}

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function burnTokens(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

contract C10INDEX is C10Token {

      address public constant LINK = 0xe9c4393a23246293a8D31BF7ab68c17d4CF90A29;//LINK Mumbai faucet

    //implementation of splitter => later set with proportions?
     function splitUsdcForBuy(uint256 usdcAmount) public pure returns (uint256) {
        uint256 usdcForToken = usdcAmount / 2;
        return usdcForToken;
    }

    // swap proto USDC for LINK => to do with Oneinch
    function swap(uint256 amountIn) public returns (uint256 amountOut) {
    }
    //will be used to deposit tokens in the contract from our MM,first when deploying approve contract on USDC approve fct
    function Deposit_Token(uint amount) external {
        IERC20 token = IERC20(0xe9DcE89B076BA6107Bb64EF30678efec11939234);//USDC MUMBAI FAUCET
        //0xF14f9596430931E177469715c591513308244e8F DAI FAUCET
        require(token.allowance(msg.sender, address(this)) >= amount, "error");
        
        require(token.transferFrom(msg.sender, address(this), amount), "error");
    }
    //check if the swap works properly
     function buyETF(uint256 usdcAmount) external {

        uint256 usdcsplitted = splitUsdcForBuy(usdcAmount);
        for ( i = 0; i < 2; i++){
            swap(usdcsplitted);
        }
        mint(usdcAmount * 1e18);
        //=> next goal : TRANSFER TO VAULT
    }
}
